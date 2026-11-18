"""Endpoint admin dashboard: guard role, ringkasan, CRUD admin, versi."""

import os
import secrets

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def admin_client(monkeypatch, tmp_path):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path}/test.db")
    monkeypatch.setenv("JWT_SECRET", secrets.token_urlsafe(48))
    monkeypatch.setenv("XENDIT_API_KEY", "")
    monkeypatch.setenv("XENDIT_WEBHOOK_TOKEN", "")
    monkeypatch.setenv("GOOGLE_CLIENT_ID", "")
    monkeypatch.setenv("AUTO_CREATE_TABLES", "true")
    monkeypatch.setenv("UPLOADS_DIR", str(tmp_path / "uploads"))
    monkeypatch.setenv("CORS_ORIGINS", "[]")
    monkeypatch.setenv("ADMIN_EMAIL", "admin@example.com")
    monkeypatch.setenv("ADMIN_PASSWORD", "Admin123!")
    if os.environ.get("ENV") is None:
        monkeypatch.setenv("ENV", "prod")
    with TestClient(create_app()) as http:
        yield http


def _login(client, role, email, password):
    resp = client.post(
        "/auth/login",
        json={"role": role, "email": email, "password": password},
    )
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


@pytest.fixture
def admin_headers(admin_client):
    return _login(admin_client, "admin", "admin@example.com", "Admin123!")


def _register(client, payload):
    resp = client.post("/auth/register", json=payload)
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_admin_ditolak_tanpa_token_dan_oleh_seller(admin_client):
    assert admin_client.get("/admin/ringkasan").status_code == 401
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    seller = _login(
        admin_client, "seller", "seller@example.com", "SandiUji123!"
    )
    assert admin_client.get("/admin/ringkasan", headers=seller).status_code == 403


def test_register_admin_ditolak(admin_client):
    # Skema register hanya mengenal seller/customer, jadi role admin
    # ditolak validasi sebelum mencapai service (guard service lapis kedua).
    resp = admin_client.post(
        "/auth/register",
        json={
            "role": "admin",
            "nama_pemilik": "Admin",
            "email": "jahat@example.com",
            "password": "SandiUji123!",
        },
    )
    assert resp.status_code == 422


def test_ringkasan_menghitung_pengguna(admin_client, admin_headers):
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    _register(
        admin_client,
        {
            "role": "customer",
            "email": "customer@example.com",
            "password": "SandiUji123!",
        },
    )
    resp = admin_client.get("/admin/ringkasan", headers=admin_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["pengguna_total"] == 3
    assert data["pengguna_per_role"]["admin"] == 1
    assert data["pengguna_per_role"]["seller"] == 1
    assert data["pengguna_per_role"]["customer"] == 1
    assert data["toko_total"] == 1


def test_admin_ubah_status_toko(admin_client, admin_headers):
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    toko = admin_client.get("/admin/toko", headers=admin_headers).json()
    assert len(toko) == 1
    toko_id = toko[0]["id"]
    assert toko[0]["status"] == "tutup"
    resp = admin_client.patch(
        f"/admin/toko/{toko_id}/status",
        json={"status": "buka"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "buka"


def test_admin_hapus_pengguna_dengan_guard(admin_client, admin_headers):
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    _register(
        admin_client,
        {
            "role": "customer",
            "email": "customer@example.com",
            "password": "SandiUji123!",
        },
    )
    users = admin_client.get("/admin/pengguna", headers=admin_headers).json()
    by_email = {u["email"]: u for u in users}
    # Seller masih punya toko -> 409.
    resp = admin_client.delete(
        f"/admin/pengguna/{by_email['seller@example.com']['id']}",
        headers=admin_headers,
    )
    assert resp.status_code == 409
    # Admin hapus diri sendiri -> 403.
    resp = admin_client.delete(
        f"/admin/pengguna/{by_email['admin@example.com']['id']}",
        headers=admin_headers,
    )
    assert resp.status_code == 403
    # Customer tanpa pesanan -> boleh dihapus.
    resp = admin_client.delete(
        f"/admin/pengguna/{by_email['customer@example.com']['id']}",
        headers=admin_headers,
    )
    assert resp.status_code == 200


def test_versi_minimum_dari_dashboard(admin_client, admin_headers):
    resp = admin_client.get("/admin/versi-minimum", headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json()["customer_sumber"] == "env"
    resp = admin_client.patch(
        "/admin/versi-minimum",
        json={"customer": "9.9.9"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["customer"] == "9.9.9"
    assert resp.json()["customer_sumber"] == "db"
    # Endpoint publik ikut nilai override.
    publik = admin_client.get(
        "/versi-minimum", params={"aplikasi": "customer", "versi": "0.1.0"}
    )
    assert publik.json()["versi_minimum"] == "9.9.9"
    assert publik.json()["wajib_update"] is True
    resp = admin_client.patch(
        "/admin/versi-minimum",
        json={"seller": "bukan-versi"},
        headers=admin_headers,
    )
    assert resp.status_code == 400


def test_kesehatan_admin(admin_client, admin_headers):
    resp = admin_client.get("/admin/kesehatan", headers=admin_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["database"] == "ok"
    assert data["smtp_terkonfigurasi"] is False
    assert data["sweeper_terakhir_jalan"] is None


def _siapkan_produk_dan_bayar(admin_client):
    """Seller + 1 produk + customer checkout COD -> pesanan + pembayaran."""
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko Uji",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    seller = _login(admin_client, "seller", "seller@example.com", "SandiUji123!")
    admin_client.patch("/toko/me/status", headers=seller, json={"status": "buka"})
    produk = admin_client.post(
        "/produk",
        headers=seller,
        json={
            "nama": "Beras",
            "harga": 15000,
            "stok": 10,
            "satuan": "kg",
            "kategori": "Sembako",
        },
    )
    assert produk.status_code == 200, produk.text
    produk = produk.json()
    _register(
        admin_client,
        {
            "role": "customer",
            "email": "customer@example.com",
            "password": "SandiUji123!",
        },
    )
    buyer = _login(admin_client, "customer", "customer@example.com", "SandiUji123!")
    alamat = admin_client.post(
        "/alamat",
        headers=buyer,
        json={
            "label": "Rumah",
            "nama_penerima": "Pembeli",
            "no_hp": "081234567890",
            "alamat_lengkap": "Jalan Melati 1",
        },
    )
    assert alamat.status_code == 201, alamat.text
    checkout = admin_client.post(
        "/checkout",
        headers={**buyer, "Idempotency-Key": "1720000000000-" + secrets.token_hex(16)},
        json={
            "alamat_id": alamat.json()["id"],
            "metode_kirim": "Instant",
            "metode_bayar": "cod",
            "items": [{"produk_id": produk["id"], "qty": 2}],
        },
    )
    assert checkout.status_code == 201, checkout.text
    return produk, checkout.json()


def test_admin_daftar_produk_dan_pembayaran(admin_client, admin_headers):
    produk, checkout = _siapkan_produk_dan_bayar(admin_client)
    resp = admin_client.get("/admin/produk", headers=admin_headers)
    assert resp.status_code == 200, resp.text
    rows = resp.json()
    assert len(rows) == 1
    assert rows[0]["nama"] == "Beras"
    assert rows[0]["toko_nama"] == "Toko Uji"
    assert rows[0]["harga"] == 15000
    assert rows[0]["stok"] == 8
    assert rows[0]["kategori"] == "Sembako"
    assert admin_client.get(
        "/admin/produk?q=beras", headers=admin_headers
    ).json() != []
    assert (
        admin_client.get("/admin/produk?q=telur", headers=admin_headers).json()
        == []
    )
    resp = admin_client.get("/admin/pembayaran", headers=admin_headers)
    assert resp.status_code == 200, resp.text
    bayar = resp.json()
    assert len(bayar) == 1
    assert bayar[0]["pesanan_kode"] == checkout["pesanan"]["kode"]
    assert bayar[0]["metode"] == "cod"
    assert bayar[0]["status"] == "pending"
    assert bayar[0]["jumlah"] == checkout["pesanan"]["total"]
    assert (
        admin_client.get(
            "/admin/pembayaran?status=paid", headers=admin_headers
        ).json()
        == []
    )
    resp = admin_client.get(
        f"/admin/pembayaran?pesanan_id={checkout['pesanan']['id']}",
        headers=admin_headers,
    )
    assert len(resp.json()) == 1
    assert resp.json()[0]["pesanan_kode"] == checkout["pesanan"]["kode"]


def test_admin_produk_dan_pembayaran_ditolak_bukan_admin(admin_client):
    assert admin_client.get("/admin/produk").status_code == 401
    assert admin_client.get("/admin/pembayaran").status_code == 401
    _register(
        admin_client,
        {
            "role": "seller",
            "nama_pemilik": "Pemilik",
            "nama_toko": "Toko",
            "email": "seller@example.com",
            "password": "SandiUji123!",
        },
    )
    seller = _login(admin_client, "seller", "seller@example.com", "SandiUji123!")
    assert admin_client.get("/admin/produk", headers=seller).status_code == 403
    assert (
        admin_client.get("/admin/pembayaran", headers=seller).status_code == 403
    )


def test_ringkasan_menghitung_produk_dan_pembayaran(admin_client, admin_headers):
    produk, checkout = _siapkan_produk_dan_bayar(admin_client)
    resp = admin_client.get("/admin/ringkasan", headers=admin_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["produk_total"] == 1
    assert data["pembayaran_total"] == 1
    assert data["pembayaran_per_status"]["pending"] == 1

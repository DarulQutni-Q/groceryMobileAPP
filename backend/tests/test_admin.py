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

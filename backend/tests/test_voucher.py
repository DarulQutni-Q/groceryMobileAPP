"""Voucher backend: seller CRUD per toko, customer hanya melihat yang aktif,
potongan dihitung server di preview dan checkout (409 tetap berlaku)."""

from uuid import uuid4

import pytest


@pytest.fixture
def dunia(client, account):
    http = client
    users = []
    for payload in [
        account,
        {"role": "customer", "email": "buy@example.com", "password": "SandiUji123!"},
    ]:
        response = http.post("/auth/register", json=payload)
        assert response.status_code == 200
        users.append({"Authorization": "Bearer " + response.json()["access_token"]})
    seller, buyer = users
    http.patch("/toko/me/status", headers=seller, json={"status": "buka"})
    toko = http.get("/toko/me", headers=seller).json()
    products = [
        http.post(
            "/produk",
            headers=seller,
            json={"nama": name, "harga": price, "stok": 10, "satuan": "pcs", "kategori": "Sembako"},
        ).json()
        for name, price in [("Beras", 15000), ("Telur", 2000)]
    ]
    address = http.post(
        "/alamat",
        headers=buyer,
        json={
            "label": "Rumah",
            "nama_penerima": "Pembeli",
            "no_hp": "081234567890",
            "alamat_lengkap": "Jalan Melati 1",
        },
    ).json()
    body = {
        "alamat_id": address["id"],
        "metode_kirim": "Instant",
        "metode_bayar": "cod",
        "items": [{"produk_id": p["id"], "qty": 2} for p in products],
    }
    return http, seller, buyer, toko, body


def _buat(http, seller, **over):
    data = {
        "kode": "HEMAT10",
        "judul": "Hemat 10%",
        "jenis": "persen",
        "persen": 10,
        "cap": 5000,
        "min_belanja": 0,
        "max_ongkir": 0,
    }
    data.update(over)
    return http.post("/voucher", headers=seller, json=data)


def test_seller_crud_dan_kode_unik_per_toko(dunia):
    http, seller, buyer, toko, body = dunia
    created = _buat(http, seller)
    assert created.status_code == 201, created.text
    assert created.json()["kode"] == "HEMAT10"
    assert created.json()["toko_id"] == toko["id"]
    assert _buat(http, seller).status_code == 400
    assert _buat(http, seller, kode="hemat10").status_code == 400
    assert http.post("/voucher", headers=buyer, json={}).status_code in (404, 403)
    mine = http.get("/voucher", headers=seller).json()
    assert len(mine) == 1
    vid = mine[0]["id"]
    off = http.patch("/voucher/" + vid, headers=seller, json={"aktif": False})
    assert off.status_code == 200 and off.json()["aktif"] is False
    assert http.get("/voucher", headers=seller).json()[0]["aktif"] is False
    assert http.delete("/voucher/" + vid, headers=seller).status_code == 204
    assert http.get("/voucher", headers=seller).json() == []


def test_customer_hanya_melihat_voucher_aktif(dunia):
    http, seller, buyer, toko, body = dunia
    _buat(http, seller)
    created = _buat(http, seller, kode="OFF10", judul="Nonaktif")
    http.patch("/voucher/" + created.json()["id"], headers=seller, json={"aktif": False})
    seen = http.get(f"/voucher/toko/{toko['id']}", headers=buyer).json()
    assert [v["kode"] for v in seen] == ["HEMAT10"]


def test_preview_dan_checkout_memakai_voucher(dunia):
    http, seller, buyer, toko, body = dunia
    assert _buat(http, seller).status_code == 201
    preview = http.post("/checkout/preview", headers=buyer, json={**body, "voucher_kode": "hemat10"})
    assert preview.status_code == 200, preview.text
    costs = preview.json()
    # Subtotal 2x15000 + 2x2000 = 34000; 10% = 3400 di bawah cap 5000.
    assert costs["subtotal"] == 34000
    assert costs["diskon"] == 3400
    assert costs["total"] == 34000 - 3400 + 1000
    assert costs["voucher_kode"] == "HEMAT10"
    key = "1720000000000-" + uuid4().hex
    result = http.post(
        "/checkout",
        headers={**buyer, "Idempotency-Key": key},
        json={**body, "voucher_kode": "HEMAT10", "total_dikonfirmasi": costs["total"]},
    )
    assert result.status_code == 201, result.text
    pesanan = result.json()["pesanan"]
    assert pesanan["diskon"] == 3400
    assert pesanan["voucher_kode"] == "HEMAT10"
    assert pesanan["total"] == 31600


def test_voucher_tidak_valid_ditolak(dunia):
    http, seller, buyer, toko, body = dunia
    assert http.post("/checkout/preview", headers=buyer, json={**body, "voucher_kode": "TIDAKADA"}).status_code == 400
    _buat(http, seller, kode="BESAR", judul="Min besar", min_belanja=100000)
    assert http.post("/checkout/preview", headers=buyer, json={**body, "voucher_kode": "BESAR"}).status_code == 400
    created = _buat(http, seller, kode="OFF10", judul="Nonaktif")
    http.patch("/voucher/" + created.json()["id"], headers=seller, json={"aktif": False})
    assert http.post("/checkout/preview", headers=buyer, json={**body, "voucher_kode": "OFF10"}).status_code == 400


def test_gratis_ongkir_diterima_tapi_tanpa_efek_saat_ongkir_nol(dunia):
    http, seller, buyer, toko, body = dunia
    assert _buat(http, seller, kode="GRATISONGKIR", judul="Gratis ongkir", jenis="gratis_ongkir", persen=0, max_ongkir=15000).status_code == 201
    preview = http.post("/checkout/preview", headers=buyer, json={**body, "voucher_kode": "GRATISONGKIR"})
    assert preview.status_code == 200, preview.text
    assert preview.json()["diskon"] == 0
    assert preview.json()["total"] == 34000 + 1000

"""Promo backend: seller CRUD, customer hanya melihat yang aktif dan belum
lewat, potongan promo masuk preview dan checkout lewat quote()."""

from datetime import datetime, timedelta, timezone
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
            json={"nama": name, "harga": price, "stok": 10, "satuan": "pcs", "kategori": "Camilan"},
        ).json()
        for name, price in [("Biskuit", 20000), ("Kerupuk", 5000)]
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
    return http, seller, buyer, toko, products, body


def _buat(http, seller, produk_id, **over):
    data = {
        "judul": "Tebus Biskuit 5rb",
        "jenis": "tebus",
        "produk_id": produk_id,
        "harga_promo": 5000,
        "min_belanja": 0,
    }
    data.update(over)
    return http.post("/promo", headers=seller, json=data)


def test_seller_crud_promo(dunia):
    http, seller, buyer, toko, products, body = dunia
    created = _buat(http, seller, products[0]["id"])
    assert created.status_code == 201, created.text
    row = created.json()
    assert row["produk"]["nama"] == "Biskuit"
    assert row["toko_nama"] == toko["nama"]
    assert http.post("/promo", headers=buyer, json={}).status_code in (404, 403)
    mine = http.get("/promo", headers=seller).json()
    assert len(mine) == 1
    off = http.patch("/promo/" + mine[0]["id"], headers=seller, json={"aktif": False})
    assert off.status_code == 200 and off.json()["aktif"] is False
    assert http.delete("/promo/" + mine[0]["id"], headers=seller).status_code == 204
    assert http.get("/promo", headers=seller).json() == []


def test_preview_memakai_harga_promo(dunia):
    http, seller, buyer, toko, products, body = dunia
    assert _buat(http, seller, products[0]["id"]).status_code == 201
    preview = http.post("/checkout/preview", headers=buyer, json=body)
    assert preview.status_code == 200, preview.text
    costs = preview.json()
    # Subtotal 2x20000 + 2x5000 = 50000; Biskuit 2x(20000-5000) = 30000.
    assert costs["subtotal"] == 50000
    assert costs["promo_diskon"] == 30000
    assert costs["diskon"] == 30000
    assert costs["total"] == 50000 - 30000 + 1000
    key = "1720000000000-" + uuid4().hex
    result = http.post(
        "/checkout",
        headers={**buyer, "Idempotency-Key": key},
        json={**body, "total_dikonfirmasi": costs["total"]},
    )
    assert result.status_code == 201, result.text
    assert result.json()["pesanan"]["diskon"] == 30000
    assert result.json()["pesanan"]["total"] == 21000


def test_tebus_butuh_min_belanja_dan_kilat_lewat_tidak_berlaku(dunia):
    http, seller, buyer, toko, products, body = dunia
    assert _buat(http, seller, products[0]["id"], min_belanja=100000).status_code == 201
    preview = http.post("/checkout/preview", headers=buyer, json=body)
    assert preview.status_code == 200
    assert preview.json()["promo_diskon"] == 0
    lewat = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    assert _buat(
        http,
        seller,
        products[1]["id"],
        judul="Kilat lewat",
        jenis="kilat",
        harga_promo=1000,
        min_belanja=0,
        berakhir_at=lewat,
    ).status_code == 201
    preview = http.post("/checkout/preview", headers=buyer, json=body)
    assert preview.json()["promo_diskon"] == 0
    aktif = http.get("/promo/aktif", headers=buyer).json()
    assert [p["judul"] for p in aktif] == ["Tebus Biskuit 5rb"]
    per_toko = http.get(f"/promo/toko/{toko['id']}", headers=buyer).json()
    assert [p["judul"] for p in per_toko] == ["Tebus Biskuit 5rb"]

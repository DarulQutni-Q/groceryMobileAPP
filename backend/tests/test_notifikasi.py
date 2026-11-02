"""Notifikasi tersimpan: ditulis saat checkout dan saat status berubah,
terbaca hanya oleh pemiliknya, badge dihitung dari yang belum dibaca."""

from unittest.mock import patch
from uuid import UUID, uuid4

import pytest
from sqlalchemy import select

from app.models.pesanan import Pesanan
from app.models.toko import Toko
from app.models.user import User
from app.services.fcm import notify_order_owner


@pytest.fixture
def pesanan_baru(client, account):
    http = client
    users = []
    for payload in [
        account,
        {"role": "customer", "email": "buy@example.com", "password": "SandiUji123!"},
        {"role": "customer", "email": "other@example.com", "password": "SandiUji123!"},
    ]:
        response = http.post("/auth/register", json=payload)
        assert response.status_code == 200
        users.append({"Authorization": "Bearer " + response.json()["access_token"]})
    seller, buyer, other = users
    http.patch("/toko/me/status", headers=seller, json={"status": "buka"})
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
    key = "1720000000000-" + uuid4().hex
    result = http.post("/checkout", headers={**buyer, "Idempotency-Key": key}, json=body)
    assert result.status_code == 201, result.text
    return http, seller, buyer, other, result.json()["pesanan"]


def test_checkout_menulis_notifikasi_pemilik(pesanan_baru):
    http, seller, buyer, other, pesanan = pesanan_baru
    seen = http.get("/notifikasi", headers=seller).json()
    assert seen["belum_dibaca"] == 1
    assert len(seen["data"]) == 1
    assert seen["data"][0]["judul"] == f"Pesanan baru {pesanan['kode']}"
    assert seen["data"][0]["pesanan_id"] == pesanan["id"]
    assert seen["data"][0]["dibaca"] is False
    assert http.get("/notifikasi", headers=buyer).json()["data"] == []
    assert http.get("/notifikasi", headers=other).json()["data"] == []
    assert http.get("/notifikasi").status_code == 401


def test_terima_menulis_notifikasi_customer_dan_baca(pesanan_baru):
    http, seller, buyer, other, pesanan = pesanan_baru
    assert http.patch(f"/pesanan/{pesanan['id']}/terima", headers=seller).status_code == 200
    seen = http.get("/notifikasi", headers=buyer).json()
    assert seen["belum_dibaca"] == 1
    assert len(seen["data"]) == 1
    row = seen["data"][0]
    assert row["judul"] == f"Pesanan {pesanan['kode']}"
    assert "Diproses" in row["isi"]
    assert row["pesanan_id"] == pesanan["id"]
    assert http.patch(f"/notifikasi/{row['id']}/baca", headers=buyer).status_code == 200
    assert http.get("/notifikasi", headers=buyer).json()["belum_dibaca"] == 0


def test_baca_semua_dan_scope(pesanan_baru):
    http, seller, buyer, other, pesanan = pesanan_baru
    http.patch(f"/pesanan/{pesanan['id']}/terima", headers=seller)
    http.patch(
        f"/pesanan/{pesanan['id']}/status", headers=seller, json={"status": "dikemas"}
    )
    buyer_rows = http.get("/notifikasi", headers=buyer).json()
    assert buyer_rows["belum_dibaca"] == 2
    assert http.patch(
        f"/notifikasi/{buyer_rows['data'][0]['id']}/baca", headers=other
    ).status_code == 404
    done = http.patch("/notifikasi/baca-semua", headers=buyer).json()
    assert done["dibaca"] == 2
    assert http.get("/notifikasi", headers=buyer).json()["belum_dibaca"] == 0


def test_push_pesanan_baru_ke_pemilik(pesanan_baru):
    http, seller, buyer, other, pesanan = pesanan_baru
    with http.app.state.sessions() as db:
        owner = db.scalar(select(User).where(User.email == "seller@example.com"))
        owner.fcm_token = "tok-owner"
        db.commit()
        order = db.get(Pesanan, UUID(pesanan["id"]))
        store = db.scalar(select(Toko).where(Toko.owner_id == owner.id))
        calls = []
        with patch(
            "app.services.fcm.send_push", side_effect=lambda *a, **k: calls.append(a)
        ):
            assert notify_order_owner(db, order, store, http.app.state.settings) is True
    assert len(calls) == 1
    assert calls[0][0] == "tok-owner"
    assert "Pesanan baru" in calls[0][1]
    assert "Rp" in calls[0][2]

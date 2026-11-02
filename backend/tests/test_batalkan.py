"""Customer membatalkan pesanan: hanya milik sendiri, hanya non-terminal,
stok kembali, pesanan berbayar ditandai rekonsiliasi manual, pemilik toko
diberi baris notifikasi dan push."""

from unittest.mock import patch
from uuid import UUID, uuid4

import pytest
from sqlalchemy import select

from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan
from app.models.produk import Produk
from app.models.toko import Toko
from app.models.user import User


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
    return http, seller, buyer, other, result.json()["pesanan"], products


def _stok(http, products):
    with http.app.state.sessions() as db:
        return {
            p["id"]: db.get(Produk, UUID(p["id"])).stok for p in products
        }


def test_customer_batalkan_pesanan_sendiri_dan_stok_kembali(pesanan_baru):
    http, seller, buyer, other, pesanan, products = pesanan_baru
    assert _stok(http, products) == {p["id"]: 8 for p in products}
    response = http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=buyer)
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "dibatalkan"
    assert _stok(http, products) == {p["id"]: 10 for p in products}
    mine = http.get("/pesanan", headers=buyer).json()
    rows = mine["data"] if isinstance(mine, dict) else mine
    assert rows[0]["status"] == "dibatalkan"


def test_customer_lain_dapat_404_dan_seller_dapat_403(pesanan_baru):
    http, seller, buyer, other, pesanan, products = pesanan_baru
    assert http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=other).status_code == 404
    assert http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=seller).status_code == 403
    assert http.patch(f"/pesanan/{pesanan['id']}/batalkan").status_code == 401


def test_pesanan_terminal_tidak_bisa_dibatalkan(pesanan_baru):
    http, seller, buyer, other, pesanan, products = pesanan_baru
    assert http.patch(f"/pesanan/{pesanan['id']}/tolak", headers=seller, json={"alasan": "Stok habis"}).status_code == 200
    assert http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=buyer).status_code == 400
    assert _stok(http, products) == {p["id"]: 10 for p in products}


def test_pesanan_dibayar_ditandai_rekonsiliasi(pesanan_baru):
    http, seller, buyer, other, pesanan, products = pesanan_baru
    with http.app.state.sessions() as db:
        payment = db.scalar(select(Pembayaran).where(Pembayaran.pesanan_id == UUID(pesanan["id"])))
        payment.status = "paid"
        db.commit()
    response = http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=buyer)
    assert response.status_code == 200, response.text
    with http.app.state.sessions() as db:
        payment = db.scalar(select(Pembayaran).where(Pembayaran.pesanan_id == UUID(pesanan["id"])))
        assert payment.status == "paid"
        assert payment.perlu_rekonsiliasi is True
    assert _stok(http, products) == {p["id"]: 10 for p in products}


def test_pembatalan_menulis_notifikasi_dan_push_pemilik(pesanan_baru):
    http, seller, buyer, other, pesanan, products = pesanan_baru
    with http.app.state.sessions() as db:
        owner = db.scalar(select(User).where(User.email == "seller@example.com"))
        owner.fcm_token = "fid-pemilik"
        db.commit()
    with patch("app.services.fcm.send_push") as push:
        response = http.patch(f"/pesanan/{pesanan['id']}/batalkan", headers=buyer)
        assert response.status_code == 200, response.text
        assert push.call_count == 1
        assert "dibatalkan" in push.call_args.args[1]
    owner_rows = http.get("/notifikasi", headers=seller).json()
    assert owner_rows["belum_dibaca"] == 2
    assert owner_rows["data"][0]["judul"] == f"Pesanan {pesanan['kode']} dibatalkan"
    buyer_rows = http.get("/notifikasi", headers=buyer).json()
    assert buyer_rows["belum_dibaca"] == 1
    assert buyer_rows["data"][0]["judul"] == f"Pesanan {pesanan['kode']}"
    assert "Dibatalkan" in buyer_rows["data"][0]["isi"]

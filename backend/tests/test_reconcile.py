"""Status check merekondisiasi pembayaran tertunda dengan invoice Xendit.

Latar: webhook Xendit tidak sampai ke backend (URL webhook di dashboard belum
diarahkan), jadi status backend mentok pending padahal invoice sudah paid di
Xendit. Endpoint status harus menemukan itu sendiri lewat find_invoice.
"""

import secrets
import time
from uuid import UUID

import pytest
from fastapi import HTTPException
from sqlalchemy import select

from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan
from app.models.produk import Produk
from app.services.xendit import get_gateway


class FakeGateway:
    def __init__(self, invoice=None, error=None):
        self.invoice = invoice
        self.error = error
        self.calls = []

    def find_invoice(self, external_id):
        self.calls.append(external_id)
        if self.error is not None:
            raise self.error
        return self.invoice


@pytest.fixture
def order_xendit(client, account):
    """Pesanan COD yang diubah jadi pembayaran Xendit tertunda."""
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
    key = f"{int(time.time() * 1000)}-{secrets.token_hex(16)}"
    result = http.post("/checkout", headers={**buyer, "Idempotency-Key": key}, json=body)
    assert result.status_code == 201
    value = result.json()
    payment_id = value["pembayaran"]["id"]
    with http.app.state.sessions() as db:
        payment = db.get(Pembayaran, UUID(payment_id))
        payment.metode = "qris"
        payment.external_id = "GM-reconcile-1"
        payment.xendit_id = "inv-reconcile-1"
        db.commit()
    return http, buyer, products, value


def _override(http, fake):
    http.app.dependency_overrides[get_gateway] = lambda: (lambda metode: fake)


def _payment(http, payment_id):
    with http.app.state.sessions() as db:
        return db.get(Pembayaran, UUID(payment_id))


def test_status_merekonsiliasi_paid_dari_xendit(order_xendit):
    http, buyer, products, value = order_xendit
    payment_id = value["pembayaran"]["id"]
    total = value["pembayaran"]["jumlah"]
    fake = FakeGateway(
        invoice={
            "id": "inv-reconcile-1",
            "external_id": "GM-reconcile-1",
            "status": "PAID",
            "amount": total,
            "currency": "IDR",
            "paid_amount": total,
            "paid_at": "2026-11-02T04:29:00+00:00",
        }
    )
    try:
        _override(http, fake)
        response = http.get(f"/pembayaran/{payment_id}/status", headers=buyer)
    finally:
        http.app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json()["status"] == "paid"
    assert response.json()["perlu_rekonsiliasi"] is False
    assert fake.calls == ["GM-reconcile-1"]
    payment = _payment(http, payment_id)
    assert payment.status == "paid"
    assert payment.stok_direservasi is True
    with http.app.state.sessions() as db:
        assert [p.stok for p in db.scalars(select(Produk).order_by(Produk.nama))] == [8, 8]


def test_status_tetap_pending_saat_xendit_gagal(order_xendit):
    http, buyer, products, value = order_xendit
    payment_id = value["pembayaran"]["id"]
    fake = FakeGateway(error=HTTPException(503, "Xendit belum dapat memproses"))
    try:
        _override(http, fake)
        response = http.get(f"/pembayaran/{payment_id}/status", headers=buyer)
    finally:
        http.app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json()["status"] == "pending"


def test_status_cod_tidak_memanggil_xendit(client, account):
    http = client
    response = http.post("/auth/register", json=account)
    assert response.status_code == 200
    seller = {"Authorization": "Bearer " + response.json()["access_token"]}
    buyer_resp = http.post(
        "/auth/register",
        json={"role": "customer", "email": "buy@example.com", "password": "SandiUji123!"},
    )
    buyer = {"Authorization": "Bearer " + buyer_resp.json()["access_token"]}
    http.patch("/toko/me/status", headers=seller, json={"status": "buka"})
    product = http.post(
        "/produk",
        headers=seller,
        json={"nama": "Beras", "harga": 15000, "stok": 10, "satuan": "pcs", "kategori": "Sembako"},
    ).json()
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
    key = f"{int(time.time() * 1000)}-{secrets.token_hex(16)}"
    result = http.post(
        "/checkout",
        headers={**buyer, "Idempotency-Key": key},
        json={
            "alamat_id": address["id"],
            "metode_kirim": "Instant",
            "metode_bayar": "cod",
            "items": [{"produk_id": product["id"], "qty": 1}],
        },
    )
    assert result.status_code == 201
    payment_id = result.json()["pembayaran"]["id"]

    def _boom(external_id):
        raise AssertionError("COD tidak boleh memanggil Xendit")

    fake = FakeGateway()
    fake.find_invoice = _boom
    try:
        _override(http, fake)
        response = http.get(f"/pembayaran/{payment_id}/status", headers=buyer)
    finally:
        http.app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json()["status"] == "pending"


def test_status_expired_membatalkan_pesanan_dan_mengembalikan_stok(order_xendit):
    http, buyer, products, value = order_xendit
    payment_id = value["pembayaran"]["id"]
    order_id = value["pesanan"]["id"]
    total = value["pembayaran"]["jumlah"]
    fake = FakeGateway(
        invoice={
            "id": "inv-reconcile-1",
            "external_id": "GM-reconcile-1",
            "status": "EXPIRED",
            "amount": total,
            "currency": "IDR",
        }
    )
    try:
        _override(http, fake)
        response = http.get(f"/pembayaran/{payment_id}/status", headers=buyer)
    finally:
        http.app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json()["status"] == "expired"
    with http.app.state.sessions() as db:
        assert db.get(Pesanan, UUID(order_id)).status == "dibatalkan"
        assert [p.stok for p in db.scalars(select(Produk).order_by(Produk.nama))] == [10, 10]

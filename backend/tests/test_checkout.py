from uuid import uuid4

import pytest
from sqlalchemy import func, select

from app.models.pesanan import Pesanan
from app.models.produk import Produk


@pytest.fixture(params=["client", "pg_client"])
def checkout(request, account):
    http = request.getfixturevalue(request.param)
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
    return http, seller, buyer, other, products, body


def assert_no_order(http, products):
    with http.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(Pesanan)) == 0
        assert [p.stok for p in db.scalars(select(Produk).order_by(Produk.nama))] == [10, 10]


def test_cod_atomic_price_snapshot_idempotency_and_customer_scope(checkout):
    http, seller, buyer, other, products, body = checkout
    key = "1720000000000-" + uuid4().hex
    preview = http.post("/checkout/preview", headers=buyer, json=body)
    assert preview.status_code == 200
    assert preview.json()["total"] == 35000
    result = http.post("/checkout", headers={**buyer, "Idempotency-Key": key}, json=body)
    assert result.status_code == 201
    value = result.json()
    assert value["payment_url"] is None
    assert value["pesanan"]["subtotal"] == 34000
    assert value["pesanan"]["biaya_layanan"] == 1000
    assert value["pembayaran"]["status"] == "pending"
    assert value["pesanan"]["kode"].startswith("DG-")
    retry = http.post("/checkout", headers={**buyer, "Idempotency-Key": key}, json=body)
    assert retry.status_code == 201
    assert retry.json()["pesanan"]["id"] == value["pesanan"]["id"]
    assert http.get("/pesanan", headers=buyer).json()["meta"]["total"] == 1
    assert http.get("/pesanan", headers=other).json()["data"] == []
    identifier = value["pembayaran"]["id"]
    assert http.get(f"/pembayaran/{identifier}/status", headers=other).status_code == 403
    assert http.get(f"/pembayaran/{identifier}/status", headers=buyer).json()["status"] == "pending"
    assert http.get(f"/pesanan/{value['pesanan']['id']}", headers=other).status_code == 404
    changed = http.post(
        "/checkout", headers={**buyer, "Idempotency-Key": key}, json={**body, "catatan": "Berubah"}
    )
    assert changed.status_code == 409
    with http.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(Pesanan)) == 1
        assert all(p.stok == 8 for p in db.scalars(select(Produk)))
    cancel = http.patch(
        f"/pesanan/{value['pesanan']['id']}/tolak", headers=seller, json={"alasan": "Toko tutup"}
    )
    assert cancel.status_code == 200
    with http.app.state.sessions() as db:
        assert all(p.stok == 10 for p in db.scalars(select(Produk)))


@pytest.mark.parametrize("invalid", ["stock", "missing", "hidden", "closed", "foreign", "price"])
def test_checkout_rejects_before_creating_order(checkout, invalid):
    http, seller, buyer, other, products, body = checkout
    if invalid == "stock":
        body["items"][1]["qty"] = 11
    elif invalid == "missing":
        body["items"][1]["produk_id"] = str(uuid4())
    elif invalid == "hidden":
        http.patch(f"/produk/{products[1]['id']}/toggle", headers=seller)
    elif invalid == "closed":
        http.patch("/toko/me/status", headers=seller, json={"status": "tutup"})
    elif invalid == "price":
        body["total_dikonfirmasi"] = 1
    result = http.post("/checkout", headers=other if invalid == "foreign" else buyer, json=body)
    assert result.status_code == (
        403 if invalid == "foreign" else 409 if invalid == "price" else 400
    )
    if invalid == "stock":
        assert "Stok Telur tidak cukup, sisa 10" in result.text
    assert_no_order(http, products)


def test_checkout_strict_validation_and_unconfigured_gateway(checkout):
    http, seller, buyer, _, products, body = checkout
    for extra in [
        {"items": []},
        {"metode_bayar": "cash"},
        {"metode_kirim": "drone"},
        {"items": [body["items"][0]] * 2},
        {"total": 1},
        {"items": [{"produk_id": products[0]["id"], "qty": -1}]},
    ]:
        assert http.post("/checkout", headers=buyer, json={**body, **extra}).status_code == 422
    assert http.post("/checkout", headers=seller, json=body).status_code == 403
    assert (
        http.post(
            "/checkout", headers={**buyer, "Content-Type": "application/json"}, content="{bad"
        ).status_code
        == 422
    )
    result = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"})
    assert result.status_code == 503
    assert_no_order(http, products)

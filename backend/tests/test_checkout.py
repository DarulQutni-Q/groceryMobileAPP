import secrets
from uuid import uuid4

import pytest
import requests
from pydantic import SecretStr
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


@pytest.fixture
def invoices(checkout, monkeypatch):
    http = checkout[0]
    token = secrets.token_urlsafe(32)
    http.app.state.settings.xendit_api_key = SecretStr("xnd_development_" + secrets.token_hex(24))
    http.app.state.settings.xendit_webhook_token = SecretStr(token)
    records, calls = [], []

    class Response:
        status_code = 200

        def __init__(self, value):
            self.value = value

        def json(self):
            return self.value

    def transport(method, url, **kwargs):
        calls.append(method)
        if method == "POST":
            payload = kwargs["json"]
            records.append(
                {
                    "id": uuid4().hex,
                    "external_id": payload["external_id"],
                    "amount": payload["amount"],
                    "currency": "IDR",
                    "status": "PENDING",
                    "invoice_url": "https://checkout-staging.xendit.co/web/" + uuid4().hex,
                }
            )
            assert kwargs["allow_redirects"] is False
            assert payload["payment_methods"] == ["QRIS"]
            return Response(records[-1])
        return Response(records)

    monkeypatch.setattr(requests, "request", transport)
    return token, records, calls


def test_qris_signed_webhook_duplicate_and_no_status_downgrade(checkout, invoices):
    http, seller, buyer, _, products, body = checkout
    token, records, calls = invoices
    result = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"})
    assert result.status_code == 201
    value = result.json()
    assert value["payment_url"].startswith("https://checkout-staging.xendit.co/")
    event = {**records[0], "status": "PAID", "paid_amount": 35000}
    assert (
        http.patch(f"/pesanan/{value['pesanan']['id']}/terima", headers=seller).status_code == 400
    )
    assert http.post("/webhook/xendit", json=event).status_code == 403
    assert (
        http.post("/webhook/xendit", headers={"X-CALLBACK-TOKEN": "wrong"}, json=event).status_code
        == 403
    )
    headers = {"X-CALLBACK-TOKEN": token}
    assert (
        http.post("/webhook/xendit", headers=headers, json={**event, "amount": 1}).status_code
        == 400
    )
    for _ in range(2):
        callback = http.post("/webhook/xendit", headers=headers, json=event)
        assert callback.status_code == 200
        assert callback.json()["status"] == "paid"
    expired = http.post("/webhook/xendit", headers=headers, json={**event, "status": "EXPIRED"})
    assert expired.json()["status"] == "paid"
    status = http.get(f"/pembayaran/{value['pembayaran']['id']}/status", headers=buyer)
    assert status.json()["status"] == "paid"
    assert status.json()["paid_at"] is not None
    assert calls == ["POST"]
    assert (
        http.patch(f"/pesanan/{value['pesanan']['id']}/terima", headers=seller).status_code == 200
    )
    with http.app.state.sessions() as db:
        assert all(p.stok == 8 for p in db.scalars(select(Produk)))
    assert (
        http.patch(
            f"/pesanan/{value['pesanan']['id']}/status",
            headers=seller,
            json={"status": "dibatalkan"},
        ).status_code
        == 200
    )
    cancelled = http.get(f"/pembayaran/{value['pembayaran']['id']}/status", headers=buyer).json()
    assert cancelled["status"] == "paid"
    assert cancelled["perlu_rekonsiliasi"] is True
    assert http.post("/webhook/xendit", headers=headers, json=event).status_code == 409
    with http.app.state.sessions() as db:
        assert all(p.stok == 10 for p in db.scalars(select(Produk)))


def test_expired_invoice_releases_stock_once(checkout, invoices):
    http, _, buyer, _, _, body = checkout
    token, records, _ = invoices
    value = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"}).json()
    event = {**records[0], "status": "EXPIRED"}
    for _ in range(2):
        assert (
            http.post("/webhook/xendit", headers={"X-CALLBACK-TOKEN": token}, json=event).json()[
                "status"
            ]
            == "expired"
        )
    assert (
        http.get(f"/pesanan/{value['pesanan']['id']}", headers=buyer).json()["status"]
        == "dibatalkan"
    )
    with http.app.state.sessions() as db:
        assert all(p.stok == 10 for p in db.scalars(select(Produk)))
    late = http.post(
        "/webhook/xendit", headers={"X-CALLBACK-TOKEN": token}, json={**event, "status": "PAID"}
    )
    assert late.status_code == 409
    payment = http.get(f"/pembayaran/{value['pembayaran']['id']}/status", headers=buyer).json()
    assert payment["status"] == "paid"
    assert payment["perlu_rekonsiliasi"] is True
    assert (
        http.get(f"/pesanan/{value['pesanan']['id']}", headers=buyer).json()["status"]
        == "dibatalkan"
    )


def test_timeout_reconciles_without_posting_a_second_invoice(checkout, invoices, monkeypatch):
    http, _, buyer, _, products, body = checkout
    _, _, calls = invoices
    original = requests.request

    def timeout_after_create(method, url, **kwargs):
        response = original(method, url, **kwargs)
        if method == "POST":
            raise requests.Timeout("response lost")
        return response

    monkeypatch.setattr(requests, "request", timeout_after_create)
    headers = {**buyer, "Idempotency-Key": "1720000000000-" + uuid4().hex}
    payload = {**body, "metode_bayar": "qris"}
    assert http.post("/checkout", headers=headers, json=payload).status_code == 503
    assert_no_order(http, products)
    recovered = http.post("/checkout", headers=headers, json=payload)
    assert recovered.status_code == 201
    assert calls == ["POST", "GET"]


def test_unknown_invoice_outcome_never_reposts(checkout, invoices, monkeypatch):
    http, _, buyer, _, products, body = checkout
    _, records, calls = invoices
    original = requests.request

    def missing(method, url, **kwargs):
        if method == "POST":
            calls.append(method)
            raise requests.Timeout("before response")
        return original(method, url, **kwargs)

    monkeypatch.setattr(requests, "request", missing)
    headers = {**buyer, "Idempotency-Key": "1720000000000-" + uuid4().hex}
    for _ in range(2):
        assert (
            http.post(
                "/checkout", headers=headers, json={**body, "metode_bayar": "qris"}
            ).status_code
            == 503
        )
    assert calls == ["POST", "GET"]
    assert records == []
    assert_no_order(http, products)


def test_store_closed_between_attempt_and_order_is_rechecked(checkout, monkeypatch):
    http, seller, buyer, _, products, body = checkout
    session_class = http.app.state.sessions.class_
    commit = session_class.commit
    closed = False

    def close_after_commit(session):
        nonlocal closed
        commit(session)
        if not closed:
            closed = True
            assert (
                http.patch("/toko/me/status", headers=seller, json={"status": "tutup"}).status_code
                == 200
            )

    monkeypatch.setattr(session_class, "commit", close_after_commit)
    response = http.post("/checkout", headers=buyer, json=body)
    assert response.status_code == 400
    assert response.headers["X-Checkout-Started"] == "false"
    assert_no_order(http, products)


def test_paid_invoice_recovered_after_response_loss(checkout, invoices, monkeypatch):
    http, _, buyer, _, products, body = checkout
    token, records, calls = invoices
    original = requests.request

    def lost(method, url, **kwargs):
        value = original(method, url, **kwargs)
        if method == "POST":
            raise requests.Timeout("lost")
        return value

    monkeypatch.setattr(requests, "request", lost)
    headers = {**buyer, "Idempotency-Key": "1720000000000-" + uuid4().hex}
    payload = {**body, "metode_bayar": "qris"}
    assert http.post("/checkout", headers=headers, json=payload).status_code == 503
    records[0]["status"] = "PAID"
    records[0]["paid_amount"] = 35000
    assert (
        http.post(
            "/webhook/xendit", headers={"X-CALLBACK-TOKEN": token}, json=records[0]
        ).status_code
        == 409
    )
    from app.models.checkout_attempt import CheckoutAttempt

    with http.app.state.sessions() as db:
        attempt = db.scalar(select(CheckoutAttempt))
        assert attempt.remote_status == "PAID"
        assert attempt.perlu_rekonsiliasi is True
    recovered = http.post("/checkout", headers=headers, json=payload)
    assert recovered.status_code == 201
    assert recovered.json()["pembayaran"]["status"] == "paid"
    assert calls == ["POST", "GET"]


def test_invalid_provider_url_is_502_and_rolls_back(checkout, invoices, monkeypatch):
    http, _, buyer, _, products, body = checkout
    original = requests.request

    def invalid_url(method, url, **kwargs):
        response = original(method, url, **kwargs)
        response.value["invoice_url"] = "https://[broken.xendit.co"
        return response

    monkeypatch.setattr(requests, "request", invalid_url)
    response = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"})
    assert response.status_code == 502
    assert_no_order(http, products)


def test_database_failure_after_order_flush_rolls_back_everything(checkout, monkeypatch):
    from sqlalchemy import event
    from sqlalchemy.exc import OperationalError

    from app.models.pembayaran import Pembayaran

    http, _, buyer, _, products, body = checkout

    def fail_payment(mapper, connection, target):
        raise OperationalError("injected failure", None, Exception("test"))

    event.listen(Pembayaran, "before_insert", fail_payment)
    try:
        result = http.post("/checkout", headers=buyer, json=body)
    finally:
        event.remove(Pembayaran, "before_insert", fail_payment)
    assert result.status_code == 503
    assert_no_order(http, products)


def test_paid_callback_during_invoice_creation_cannot_be_downgraded(
    checkout, invoices, monkeypatch
):
    http, _, buyer, _, _, body = checkout
    if http.app.state.engine.dialect.name != "postgresql":
        pytest.skip("Callback concurrent dengan transaksi diuji pada PostgreSQL")
    token, _, _ = invoices
    original = requests.request

    def callback_before_response(method, url, **kwargs):
        response = original(method, url, **kwargs)
        if method == "POST":
            result = http.post(
                "/webhook/xendit",
                headers={"X-CALLBACK-TOKEN": token},
                json={**response.value, "status": "PAID", "paid_amount": 35000},
            )
            assert result.status_code == 409
        return response

    monkeypatch.setattr(requests, "request", callback_before_response)
    result = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"})
    assert result.status_code == 201
    assert result.json()["pembayaran"]["status"] == "paid"


def test_checkout_rate_limit_and_request_id(checkout):
    http, _, buyer, _, _, body = checkout
    headers = {**buyer, "Idempotency-Key": "1720000000000-" + uuid4().hex}
    for _ in range(10):
        assert http.post("/checkout", headers=headers, json=body).status_code == 201
    limited = http.post("/checkout", headers=headers, json=body)
    assert limited.status_code == 429
    assert "X-Request-ID" in limited.headers
    assert 1 <= int(limited.headers["Retry-After"]) <= 60


def test_postgres_two_customers_cannot_buy_the_same_last_stock(checkout):
    from concurrent.futures import ThreadPoolExecutor
    from threading import Barrier

    http, _, buyer, other, _, body = checkout
    if http.app.state.engine.dialect.name != "postgresql":
        pytest.skip("Penguncian stok concurrent diuji pada PostgreSQL")
    address = http.post(
        "/alamat",
        headers=other,
        json={
            "label": "Kantor",
            "nama_penerima": "Pembeli lain",
            "no_hp": "081234567899",
            "alamat_lengkap": "Jalan lain",
        },
    ).json()
    items = [{**item, "qty": 10} for item in body["items"]]
    barrier = Barrier(2)

    def buy(headers, address_id):
        barrier.wait(timeout=5)
        return http.post(
            "/checkout", headers=headers, json={**body, "alamat_id": address_id, "items": items}
        ).status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        first = pool.submit(buy, buyer, body["alamat_id"])
        second = pool.submit(buy, other, address["id"])
        assert sorted([first.result(timeout=20), second.result(timeout=20)]) == [201, 400]
    with http.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(Pesanan)) == 1
        assert all(p.stok == 0 for p in db.scalars(select(Produk)))


def test_provider_integral_numeric_amount_accepts_float_but_not_fraction(
    checkout, invoices, monkeypatch
):
    http, _, buyer, _, products, body = checkout
    original = requests.request

    def numeric_amount(method, url, **kwargs):
        response = original(method, url, **kwargs)
        response.value["amount"] = float(response.value["amount"])
        return response

    monkeypatch.setattr(requests, "request", numeric_amount)
    result = http.post("/checkout", headers=buyer, json={**body, "metode_bayar": "qris"})
    assert result.status_code == 201
    token = invoices[0]
    event = {**invoices[1][0], "amount": 35000.5, "status": "PAID"}
    assert (
        http.post("/webhook/xendit", headers={"X-CALLBACK-TOKEN": token}, json=event).status_code
        == 422
    )

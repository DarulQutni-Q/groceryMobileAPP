import re
from datetime import datetime, timedelta

import pytest


@pytest.fixture
def dev_client(monkeypatch, request):
    monkeypatch.setenv("ENV", "dev")
    return request.getfixturevalue("client")


def seller(client, account):
    response = client.post("/auth/register", json=account)
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def product(client, headers):
    response = client.post(
        "/produk",
        headers=headers,
        json={"nama": "Beras Uji", "harga": 15000, "stok": 20, "satuan": "kg", "kategori": "Beras"},
    )
    assert response.status_code == 200
    return response.json()


def order(client, headers, produk_id):
    response = client.post(
        "/pesanan/internal/test",
        headers=headers,
        json={
            "items": [{"produk_id": produk_id, "qty": 2}],
            "ongkir": 5000,
            "diskon": 1000,
            "biaya_layanan": 500,
            "alamat_kirim": "Jalan Pengujian 3",
            "metode_kirim": "Instant",
            "slot_waktu": "Hari ini 15.00-17.00",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_dummy_order_is_owned_calculated_and_snapshotted(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    pesanan = order(client, headers, produk["id"])
    assert re.fullmatch(r"DG-\d{5}", pesanan["kode"])
    assert pesanan["status"] == "baru"
    assert pesanan["customer_id"] is None
    assert pesanan["subtotal"] == 30000
    assert pesanan["total"] == 34500
    assert pesanan["items"][0]["nama_snapshot"] == "Beras Uji"
    client.put(
        f"/produk/{produk['id']}", headers=headers, json={"nama": "Beras Baru", "harga": 20000}
    )
    detail = client.get(f"/pesanan/{pesanan['id']}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["items"][0]["harga_snapshot"] == 15000
    assert detail.json()["items"][0]["nama_snapshot"] == "Beras Uji"
    listed = client.get("/pesanan?status=baru", headers=headers)
    assert listed.status_code == 200
    assert [item["id"] for item in listed.json()] == [pesanan["id"]]
    assert (
        client.get("/pesanan", headers=headers, params={"status": "tidak-valid"}).status_code == 422
    )


def test_dummy_endpoint_is_absent_outside_dev(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    order(client, headers, produk["id"])
    for environment in ("prod", "staging", ""):
        client.app.state.settings.env = environment
        response = client.post("/pesanan/internal/test", headers=headers)
        assert response.status_code == 404
    assert len(client.get("/pesanan", headers=headers).json()) == 1


def test_default_environment_disables_dummy(client, account):
    headers = seller(client, account)
    assert client.post("/pesanan/internal/test", headers=headers).status_code == 404
    assert client.get("/pesanan", headers=headers).json() == []


def test_order_transitions_are_sequential_and_tabs_group_final_states(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    first, rejected, pending = [order(client, headers, produk["id"]) for _ in range(3)]
    path = f"/pesanan/{first['id']}"
    assert (
        client.patch(path + "/status", headers=headers, json={"status": "selesai"}).status_code
        == 400
    )
    accepted = client.patch(path + "/terima", headers=headers)
    assert accepted.status_code == 200
    assert accepted.json()["status"] == "diproses"
    assert client.patch(path + "/terima", headers=headers).status_code == 400
    for status in ("dikemas", "diantar", "selesai"):
        response = client.patch(path + "/status", headers=headers, json={"status": status})
        assert response.status_code == 200
        assert response.json()["status"] == status
        if status != "selesai":
            assert len(client.get("/pesanan?status=diproses", headers=headers).json()) == 1
    rejected_path = f"/pesanan/{rejected['id']}"
    for payload in ({}, {"alasan": ""}, {"alasan": "   "}):
        assert (
            client.patch(rejected_path + "/tolak", headers=headers, json=payload).status_code == 422
        )
    assert (
        client.patch(
            rejected_path + "/status", headers=headers, json={"status": "ditolak"}
        ).status_code
        == 400
    )
    rejection = client.patch(
        rejected_path + "/tolak", headers=headers, json={"alasan": " Stok Habis "}
    )
    assert rejection.status_code == 200
    assert rejection.json()["tolak_alasan"] == "Stok Habis"
    assert rejection.json()["status"] == "ditolak"
    assert len(client.get("/pesanan?status=selesai", headers=headers).json()) == 2
    assert [p["id"] for p in client.get("/pesanan?status=baru", headers=headers).json()] == [
        pending["id"]
    ]
    assert client.patch(rejected_path + "/terima", headers=headers).status_code == 400
    assert (
        client.patch(path + "/status", headers=headers, json={"status": "dibatalkan"}).status_code
        == 400
    )


def test_order_undo_has_server_deadline_and_cannot_rewind_other_stages(
    dev_client, account, monkeypatch
):
    client = dev_client
    headers = seller(client, account)
    pesanan = order(client, headers, product(client, headers)["id"])
    path = f"/pesanan/{pesanan['id']}"
    accepted = client.patch(path + "/terima", headers=headers)
    assert accepted.status_code == 200
    accepted = accepted.json()
    deadline = datetime.fromisoformat(accepted["undo_until"])
    assert deadline - datetime.fromisoformat(accepted["accepted_at"]) == timedelta(seconds=10)
    assert datetime.fromisoformat(accepted["server_time"]) <= deadline
    undone = client.patch(path + "/urungkan", headers=headers)
    assert undone.status_code == 200
    assert undone.json()["status"] == "baru"
    assert undone.json()["accepted_at"] is None
    assert client.patch(path + "/urungkan", headers=headers).status_code == 400
    accepted = client.patch(path + "/terima", headers=headers).json()
    deadline = datetime.fromisoformat(accepted["undo_until"])
    monkeypatch.setattr("app.services.pesanan.now_utc", lambda: deadline)
    assert client.patch(path + "/urungkan", headers=headers).status_code == 400
    assert client.get(path, headers=headers).json()["status"] == "diproses"
    assert (
        client.patch(path + "/status", headers=headers, json={"status": "baru"}).status_code == 400
    )
    assert (
        client.patch(path + "/status", headers=headers, json={"status": "dikemas"}).status_code
        == 200
    )
    assert client.patch(path + "/urungkan", headers=headers).status_code == 400


def test_orders_and_dummy_products_never_cross_store_boundaries(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    pesanan = order(client, headers, produk["id"])
    other = seller(client, dict(account, email="other@example.com"))
    assert client.get("/pesanan", headers=other).json() == []
    assert client.get("/pesanan").status_code == 401
    path = f"/pesanan/{pesanan['id']}"
    for method, suffix, payload in (
        ("GET", "", None),
        ("PATCH", "/terima", None),
        ("PATCH", "/tolak", {"alasan": "Stok Habis"}),
        ("PATCH", "/status", {"status": "dibatalkan"}),
        ("PATCH", "/urungkan", None),
    ):
        assert client.request(method, path + suffix, headers=other, json=payload).status_code == 404
    assert (
        client.post(
            "/pesanan/internal/test",
            headers=other,
            json={"items": [{"produk_id": produk["id"], "qty": 1}]},
        ).status_code
        == 404
    )
    assert (
        client.post(
            "/pesanan/internal/test", headers=headers, json={"toko_id": "spoofed"}
        ).status_code
        == 422
    )


def test_cancellation_is_terminal(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    pesanan = order(client, headers, product(client, headers)["id"])
    path = f"/pesanan/{pesanan['id']}"
    result = client.patch(path + "/status", headers=headers, json={"status": "dibatalkan"})
    assert result.status_code == 200
    assert result.json()["status"] == "dibatalkan"
    assert client.patch(path + "/terima", headers=headers).status_code == 400
    assert (
        client.patch(path + "/tolak", headers=headers, json={"alasan": "Stok Habis"}).status_code
        == 400
    )


def test_invalid_costs_and_duplicate_items_do_not_create_orders(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    item = {"produk_id": produk["id"], "qty": 1}
    for payload in (
        {"items": [item, item]},
        {"ongkir": -1},
        {"diskon": 999999},
        {"items": [dict(item, qty=10000)], "ongkir": 2147483647},
        {"items": []},
        {"ongkir": True},
    ):
        response = client.post("/pesanan/internal/test", headers=headers, json=payload)
        assert response.status_code == 422
    assert client.get("/pesanan", headers=headers).json() == []


def test_order_code_collisions_retry_then_fail_without_partial_order(
    dev_client, account, monkeypatch
):
    client = dev_client
    headers = seller(client, account)
    produk = product(client, headers)
    monkeypatch.setattr("app.services.pesanan.secrets.randbelow", lambda _: 5)
    assert order(client, headers, produk["id"])["kode"] == "DG-10005"
    codes = iter([5, 6])
    monkeypatch.setattr("app.services.pesanan.secrets.randbelow", lambda _: next(codes))
    assert order(client, headers, produk["id"])["kode"] == "DG-10006"
    monkeypatch.setattr("app.services.pesanan.secrets.randbelow", lambda _: 5)
    response = client.post("/pesanan/internal/test", headers=headers)
    assert response.status_code == 503
    saved = client.get("/pesanan", headers=headers).json()
    assert len(saved) == 2
    assert sum(len(p["items"]) for p in saved) == 2

from uuid import uuid4

import pytest
from sqlalchemy import event


@pytest.fixture(params=["client", "pg_client"])
def catalog(request, account):
    client = request.getfixturevalue(request.param)

    def register(payload):
        response = client.post("/auth/register", json=payload)
        assert response.status_code == 200
        return {"Authorization": "Bearer " + response.json()["access_token"]}

    seller = register(account)
    other = register({**account, "email": "other@example.com", "nama_toko": "Toko Tutup"})
    buyer = register({"role": "customer", "email": "buyer@example.com", "password": "SandiUji123!"})
    assert (
        client.patch("/toko/me/status", headers=seller, json={"status": "buka"}).status_code == 200
    )
    assert (
        client.put(
            "/toko/me", headers=seller, json={"rekening_bank": "rekening-private-marker"}
        ).status_code
        == 200
    )
    days = [
        {"hari": day, "jam_buka": "08:00", "jam_tutup": "23:00", "is_tutup": False}
        for day in ["senin", "selasa", "rabu", "kamis", "jumat", "sabtu", "minggu"]
    ]
    assert client.put("/toko/me/jam-buka", headers=seller, json=days).status_code == 200
    products = []
    names = ["Indomie Spesial", "Beras Premium", "Susu Habis"] + [f"Beras {i}" for i in range(9)]
    for index, name in enumerate(names):
        payload = {
            "nama": name,
            "harga": 15000 + index,
            "stok": 0 if index == 2 else 25,
            "satuan": "pcs",
            "kategori": "Mie" if index == 0 else "Susu" if index == 2 else "Beras",
        }
        response = client.post("/produk", headers=seller, json=payload)
        assert response.status_code == 200
        products.append(response.json())
    hidden = client.post(
        "/produk",
        headers=seller,
        json={
            "nama": "Disembunyikan",
            "harga": 1000,
            "stok": 5,
            "satuan": "pcs",
            "kategori": "Hilang",
        },
    ).json()
    assert client.patch(f"/produk/{hidden['id']}/toggle", headers=seller).status_code == 200
    closed = client.post(
        "/produk",
        headers=other,
        json={
            "nama": "Produk Toko Tutup",
            "harga": 2000,
            "stok": 5,
            "satuan": "pcs",
            "kategori": "Rahasia",
        },
    ).json()
    return client, seller, other, buyer, products, hidden, closed


def test_customer_can_search_filter_and_paginate_visible_products(catalog):
    client, _, _, buyer, products, _, closed = catalog
    response = client.get("/produk", headers=buyer)
    assert response.status_code == 200
    result = response.json()
    assert result["meta"] == {"page": 1, "per_page": 20, "total": 12, "total_pages": 1}
    assert {p["id"] for p in result["data"]} == {p["id"] for p in products}
    assert (
        client.get("/produk?q=indomie", headers=buyer).json()["data"][0]["nama"]
        == "Indomie Spesial"
    )
    rice = client.get("/produk?kategori=Beras", headers=buyer).json()
    assert rice["meta"]["total"] == 10
    assert all(p["kategori"] == "Beras" for p in rice["data"])
    page = client.get("/produk?page=2&per_page=5", headers=buyer).json()
    assert len(page["data"]) == 5
    assert page["meta"] == {"page": 2, "per_page": 5, "total": 12, "total_pages": 3}
    assert (
        client.get("/produk?page=1&per_page=200", headers=buyer).json()["meta"]["per_page"] == 100
    )
    assert client.get("/produk?q=%25", headers=buyer).json()["data"] == []
    assert client.get(f"/produk?toko_id={closed['toko_id']}", headers=buyer).json()["data"] == []
    assert (
        client.get(f"/produk?toko_id={products[0]['toko_id']}", headers=buyer).json()["meta"][
            "total"
        ]
        == 12
    )


def test_product_details_hide_closed_and_unavailable_items_but_keep_zero_stock(catalog):
    client, _, _, buyer, products, hidden, closed = catalog
    result = client.get(f"/produk/{products[0]['id']}", headers=buyer)
    assert result.status_code == 200
    assert result.json() == products[0]
    empty = client.get(f"/produk/{products[2]['id']}", headers=buyer)
    assert empty.status_code == 200 and empty.json()["stok"] == 0
    for id in [hidden["id"], closed["id"], str(uuid4())]:
        assert client.get(f"/produk/{id}", headers=buyer).status_code == 404


def test_public_store_schema_excludes_owner_and_bank_and_paginates_products(catalog):
    client, seller, other, buyer, products, _, closed = catalog
    result = client.get("/toko", headers=buyer)
    assert result.status_code == 200
    stores = result.json()
    assert stores["meta"]["total"] == 1
    store = stores["data"][0]
    assert store["id"] == products[0]["toko_id"]
    assert store["status"] == "buka"
    assert store["jam_buka"] == "08:00:00" and store["jam_tutup"] == "23:00:00"
    assert "owner_id" not in store and "rekening_bank" not in store
    assert "rekening-private-marker" not in result.text
    detail = client.get(f"/toko/{store['id']}?page=2&per_page=5", headers=buyer)
    assert detail.status_code == 200
    assert len(detail.json()["produk"]) == 5
    assert detail.json()["meta"]["total"] == 12
    assert "owner_id" not in detail.json() and "rekening_bank" not in detail.json()
    assert client.get(f"/toko/{closed['toko_id']}", headers=buyer).status_code == 404
    assert client.get(f"/toko/{uuid4()}", headers=buyer).status_code == 404
    assert (
        client.patch("/toko/me/status", headers=other, json={"status": "buka"}).status_code == 200
    )
    assert client.get("/toko", headers=buyer).json()["meta"]["total"] == 2
    assert (
        client.get("/toko/me", headers=seller).json()["rekening_bank"] == "rekening-private-marker"
    )


def test_categories_and_real_promos_are_authenticated(catalog):
    client, _, _, buyer, _, _, _ = catalog
    result = client.get("/kategori", headers=buyer)
    assert result.status_code == 200
    assert result.json() == ["Beras", "Mie", "Susu"]
    # Demo promo dihapus (item 6): banner kini dari promo toko aktif,
    # dan fixture ini tidak membuat promo apa pun, jadi daftarnya kosong.
    promos = client.get("/promo/aktif", headers=buyer)
    assert promos.status_code == 200 and promos.json() == []
    for path in ["/produk", "/toko", "/kategori", "/promo/aktif"]:
        assert client.get(path).status_code == 401


def test_customer_reads_do_not_weaken_any_seller_mutation_or_owner_scope(catalog):
    client, seller, other, buyer, products, _, _ = catalog
    legacy = client.get("/produk", headers=seller)
    assert legacy.status_code == 200 and isinstance(legacy.json(), list)
    assert len(legacy.json()) == 13
    assert all(p["toko_id"] == products[0]["toko_id"] for p in legacy.json())
    foreign = client.get(f"/produk?toko_id={products[0]['toko_id']}", headers=other)
    assert foreign.status_code == 200 and foreign.json() == []
    path = f"/produk/{products[0]['id']}"
    for method, route, data in [
        (
            "POST",
            "/produk",
            {"nama": "Tidak boleh", "harga": 1, "stok": 1, "satuan": "pcs", "kategori": "Beras"},
        ),
        ("PUT", path, {"harga": 10}),
        ("DELETE", path, None),
        ("PATCH", path + "/toggle", None),
        ("PUT", "/toko/me", {"nama": "Tidak boleh"}),
        ("PATCH", "/toko/me/status", {"status": "tutup"}),
    ]:
        assert client.request(method, route, headers=buyer, json=data).status_code == 403
    assert client.get(path, headers=seller).json() == products[0]
    assert client.get(path, headers=other).status_code == 404


def test_catalog_validates_query_parameters_without_500(catalog):
    client, _, _, buyer, products, _, _ = catalog
    for path in [
        "/produk?page=0",
        "/produk?per_page=-1",
        "/produk?toko_id=ngawur",
        "/produk/ngawur",
        "/toko/ngawur",
        "/toko?page=-1",
        "/toko?per_page=0",
        "/produk?q=%00",
        "/produk?kategori=%00",
    ]:
        assert client.get(path, headers=buyer).status_code == 422
    assert client.get(f"/produk/{products[0]['id']}", headers=buyer).status_code == 200


def test_catalog_queries_are_bounded_independent_of_product_count(catalog):
    client, _, _, buyer, _, _, _ = catalog
    engine = client.app.state.engine
    statements = []

    def record(connection, cursor, statement, parameters, context, executemany):
        statements.append(statement)

    event.listen(engine, "before_cursor_execute", record)
    try:
        for route in ["/produk?per_page=20", "/toko"]:
            statements.clear()
            result = client.get(route, headers=buyer)
            assert result.status_code == 200
            assert len(statements) <= 3
    finally:
        event.remove(engine, "before_cursor_execute", record)

import pytest
from sqlalchemy import event, select
from test_a5_queries import seeded_orders as seeded_orders
from test_pesanan import product, seller

from app.models.pesanan import Pesanan, PesananItem


def test_product_pagination_preserves_legacy_list_and_owned_filtered_counts(client, account):
    headers = seller(client, account)
    for _ in range(23):
        product(client, headers)
    other = seller(client, {**account, "email": "other@example.com"})
    product(client, other)
    legacy = client.get("/produk", headers=headers)
    assert isinstance(legacy.json(), list)
    assert len(legacy.json()) == 23
    first = client.get("/produk?page=1", headers=headers).json()
    assert first["meta"] == {"page": 1, "per_page": 20, "total": 23, "total_pages": 2}
    assert len(first["data"]) == 20
    second = client.get("/produk?page=2", headers=headers).json()
    assert len(second["data"]) == 3
    assert not {row["id"] for row in first["data"]} & {row["id"] for row in second["data"]}
    capped = client.get("/produk?per_page=200", headers=headers).json()
    assert capped["meta"] == {"page": 1, "per_page": 100, "total": 23, "total_pages": 1}
    assert len(capped["data"]) <= 100
    filtered = client.get("/produk?page=1&kategori=TidakAda", headers=headers).json()
    assert filtered == {
        "data": [],
        "meta": {"page": 1, "per_page": 20, "total": 0, "total_pages": 0},
    }
    for query in ["page=0", "page=-1", "page=2147483648", "page=abc", "per_page=0", "per_page=-1"]:
        assert client.get("/produk?" + query, headers=headers).status_code == 422


@pytest.mark.parametrize(
    "query,expected_count,total",
    [
        ("page=1", 20, 20),
        ("page=2", 0, 20),
        ("per_page=200", 20, 20),
        ("page=1&status=selesai", 0, 0),
    ],
)
def test_order_pagination_including_empty_pages_needs_three_queries(
    seeded_orders,
    query,
    expected_count,
    total,
):
    client, headers = seeded_orders
    statements = []

    def record(connection, cursor, statement, parameters, context, executemany):
        statements.append(statement)

    event.listen(client.app.state.engine, "before_cursor_execute", record)
    try:
        response = client.get("/pesanan?" + query, headers=headers)
    finally:
        event.remove(client.app.state.engine, "before_cursor_execute", record)
    assert response.status_code == 200
    data = response.json()
    assert len(data["data"]) == expected_count
    assert data["meta"]["total"] == total
    assert len(statements) <= 3
    assert all(row["items"] and row["nama_pembeli"] == "Pembeli Uji" for row in data["data"])


def test_pagination_limits_orders_instead_of_joined_item_rows(seeded_orders):
    client, headers = seeded_orders
    with client.app.state.sessions() as db:
        orders = db.scalars(select(Pesanan)).all()
        db.add_all(
            PesananItem(pesanan_id=row.id, nama_snapshot="Minyak", harga_snapshot=10000, qty=1)
            for row in orders
        )
        db.commit()
    response = client.get("/pesanan?per_page=7", headers=headers)
    assert response.status_code == 200
    assert len(response.json()["data"]) == 7
    assert response.json()["meta"]["total"] == 20
    assert all(len(row["items"]) == 2 for row in response.json()["data"])

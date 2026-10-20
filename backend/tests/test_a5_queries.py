from uuid import UUID

import pytest
from sqlalchemy import event, update
from test_pesanan import order, product, seller

from app.models.pesanan import Pesanan
from app.models.user import User


@pytest.fixture(params=["client", "pg_client"])
def seeded_orders(request, monkeypatch, account):
    monkeypatch.setenv("ENV", "dev")
    client = request.getfixturevalue(request.param)
    headers = seller(client, account)
    produk = product(client, headers)
    ids = [UUID(order(client, headers, produk["id"])["id"]) for _ in range(20)]
    with client.app.state.sessions() as db:
        customer = User(nama="Pembeli Uji", email="customer@example.com", role="customer")
        db.add(customer)
        db.flush()
        db.execute(update(Pesanan).where(Pesanan.id.in_(ids)).values(customer_id=customer.id))
        db.commit()
    return client, headers


def test_twenty_orders_with_items_and_customer_need_at_most_three_queries(seeded_orders):
    client, headers = seeded_orders
    statements = []

    def record(connection, cursor, statement, parameters, context, executemany):
        statements.append(statement)

    engine = client.app.state.engine
    event.listen(engine, "before_cursor_execute", record)
    engine.echo = True
    try:
        response = client.get("/pesanan", headers=headers)
    finally:
        engine.echo = False
        event.remove(engine, "before_cursor_execute", record)
    assert response.status_code == 200
    assert len(response.json()) == 20
    assert all(
        len(row["items"]) == 1 and row["nama_pembeli"] == "Pembeli Uji" for row in response.json()
    )
    assert len(statements) <= 3

from concurrent.futures import ThreadPoolExecutor, TimeoutError
from datetime import datetime, timedelta, timezone
from threading import Event
from uuid import UUID

import pytest
from fastapi import Depends, Request
from sqlalchemy import event
from sqlalchemy.orm import Session
from test_pesanan import order, product, seller

from app.db.session import get_db
from app.models.toko import Toko
from app.routers.pesanan import get_pesanan
from app.services.toko import get_store


@pytest.fixture
def dev_pg_client(pg_client):
    pg_client.app.state.settings.env = "dev"
    return pg_client


def test_snapshot_survives_product_update_and_delete_in_postgres(dev_pg_client, account):
    client = dev_pg_client
    headers = seller(client, account)
    produk = product(client, headers)
    pesanan = order(client, headers, produk["id"])
    path = f"/produk/{produk['id']}"
    assert (
        client.put(path, headers=headers, json={"nama": "Nama Baru", "harga": 50000}).status_code
        == 200
    )
    assert client.delete(path, headers=headers).status_code == 200
    detail = client.get(f"/pesanan/{pesanan['id']}", headers=headers).json()
    assert detail["items"][0]["produk_id"] is None
    assert detail["items"][0]["nama_snapshot"] == "Beras Uji"
    assert detail["items"][0]["harga_snapshot"] == 15000
    assert detail["total"] == 34500


def test_postgres_timezone_preserves_timestamps_and_undo_deadline(dev_pg_client, account):
    client = dev_pg_client

    def jakarta(connection, record, proxy):
        with connection.cursor() as cursor:
            cursor.execute("SET TIME ZONE 'Asia/Jakarta'")

    event.listen(client.app.state.engine, "checkout", jakarta)
    headers = seller(client, account)
    pesanan = order(client, headers, product(client, headers)["id"])
    path = f"/pesanan/{pesanan['id']}"
    first = client.get(path, headers=headers).json()
    assert datetime.fromisoformat(first["created_at"]) == datetime.fromisoformat(
        pesanan["created_at"]
    )
    assert client.patch(path + "/terima", headers=headers).status_code == 200
    accepted = client.get(path, headers=headers).json()
    accepted_at = datetime.fromisoformat(accepted["accepted_at"])
    assert abs(datetime.now(timezone.utc) - accepted_at) < timedelta(seconds=5)
    assert datetime.fromisoformat(accepted["undo_until"]) - accepted_at == timedelta(seconds=10)
    assert client.patch(path + "/urungkan", headers=headers).status_code == 200


@pytest.mark.parametrize(
    "paused,other,payload,expected",
    [
        ("terima", "tolak", {"alasan": "Stok Habis"}, "diproses"),
        ("urungkan", "status", {"status": "dikemas"}, "baru"),
    ],
)
def test_competing_order_transitions_are_serialized(
    dev_pg_client, account, paused, other, payload, expected
):
    client = dev_pg_client
    headers = seller(client, account)
    pesanan = order(client, headers, product(client, headers)["id"])
    path = f"/pesanan/{pesanan['id']}"
    if paused == "urungkan":
        assert client.patch(path + "/terima", headers=headers).status_code == 200
    loaded, release = Event(), Event()

    def pause(
        pesanan_id: UUID,
        request: Request,
        toko: Toko = Depends(get_store),
        db: Session = Depends(get_db),
    ):
        result = get_pesanan(pesanan_id, toko, db)
        if request.url.path.endswith("/" + paused):
            loaded.set()
            assert release.wait(10)
        return result

    client.app.dependency_overrides[get_pesanan] = pause
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(client.patch, path + "/" + paused, headers=headers)
            assert loaded.wait(10)
            second = pool.submit(client.patch, path + "/" + other, headers=headers, json=payload)
            try:
                second.result(timeout=0.3)
            except TimeoutError:
                pass
            finally:
                release.set()
            assert first.result(timeout=10).status_code == 200
            assert second.result(timeout=10).status_code == 400
        assert client.get(path, headers=headers).json()["status"] == expected
    finally:
        release.set()
        client.app.dependency_overrides.clear()

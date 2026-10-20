from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Event
from uuid import UUID

import pytest
from fastapi import Request
from sqlalchemy import event, update
from test_pesanan import seller

from app.db.session import get_db
from app.models.pesanan import Pesanan
from app.models.produk import Produk


@pytest.fixture(params=["client", "pg_client"])
def dev_client(monkeypatch, request):
    monkeypatch.setenv("ENV", "dev")
    return request.getfixturevalue(request.param)


def test_empty_reports_return_zero_and_require_seller(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    response = client.get("/laporan/ringkasan", headers=headers)
    assert response.status_code == 200
    assert response.json() == {
        "total_penjualan": 0,
        "jumlah_pesanan": 0,
        "jumlah_produk_terjual": 0,
        "perbandingan_minggu_lalu": 0.0,
        "ada_pembanding": False,
        "penjualan_per_hari": [],
    }
    response = client.get("/laporan/produk-terlaris", headers=headers)
    assert response.status_code == 200
    assert response.json() == []
    for path in ("/laporan/ringkasan", "/laporan/produk-terlaris"):
        assert client.get(path).status_code == 401
        assert client.get(path, headers=headers, params={"range": "1h"}).status_code == 422
    for limit in (0, -1, 101):
        assert (
            client.get(
                "/laporan/produk-terlaris", headers=headers, params={"limit": limit}
            ).status_code
            == 422
        )


def create_product(client, headers, nama, harga):
    response = client.post(
        "/produk",
        headers=headers,
        json={"nama": nama, "harga": harga, "stok": 100, "satuan": "pcs", "kategori": "Sembako"},
    )
    assert response.status_code == 200
    return response.json()["id"]


def create_order(client, headers, items, status="baru", **fees):
    response = client.post("/pesanan/internal/test", headers=headers, json={"items": items, **fees})
    assert response.status_code == 200
    path = "/pesanan/" + response.json()["id"]
    if status == "ditolak":
        assert (
            client.patch(
                path + "/tolak", headers=headers, json={"alasan": "Stok Habis"}
            ).status_code
            == 200
        )
    elif status == "dibatalkan":
        assert (
            client.patch(path + "/status", headers=headers, json={"status": status}).status_code
            == 200
        )
    elif status != "baru":
        assert client.patch(path + "/terima", headers=headers).status_code == 200
        for step in ("dikemas", "diantar", "selesai"):
            if status == "diproses":
                break
            assert (
                client.patch(path + "/status", headers=headers, json={"status": step}).status_code
                == 200
            )
            if step == status:
                break
    return response.json()["id"]


def test_completed_owned_orders_are_aggregated_without_duplicate_totals(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    beras = create_product(client, headers, "Beras", 15000)
    minyak = create_product(client, headers, "Minyak", 20000)
    items = [{"produk_id": beras, "qty": 2}, {"produk_id": minyak, "qty": 1}]
    for _ in range(2):
        create_order(client, headers, items, "selesai", diskon=1000, ongkir=5000, biaya_layanan=500)
    create_order(client, headers, [{"produk_id": beras, "qty": 1}], "selesai")
    for status in ("baru", "diproses", "dikemas", "diantar", "ditolak", "dibatalkan"):
        create_order(client, headers, [{"produk_id": beras, "qty": 50}], status)
    other = seller(client, {**account, "email": "other@example.com"})
    other_product = create_product(client, other, "Produk toko lain", 99000)
    create_order(client, other, [{"produk_id": other_product, "qty": 99}], "selesai")
    response = client.get("/laporan/ringkasan?range=7h", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total_penjualan"] == 124000
    assert data["jumlah_pesanan"] == 3
    assert data["jumlah_produk_terjual"] == 7
    assert data["perbandingan_minggu_lalu"] == 0.0
    assert data["ada_pembanding"] is False
    days = data["penjualan_per_hari"]
    assert len(days) == 7
    assert sum(day["total"] for day in days) == 124000
    assert days[-1] == {
        "tanggal": datetime.now(timezone(timedelta(hours=7))).date().isoformat(),
        "total": 124000,
    }
    ranking = client.get("/laporan/produk-terlaris", headers=headers)
    assert ranking.status_code == 200
    assert ranking.json() == [
        {
            "produk_id": beras,
            "nama": "Beras",
            "foto_url": None,
            "total_qty": 5,
            "total_rupiah": 75000,
        },
        {
            "produk_id": minyak,
            "nama": "Minyak",
            "foto_url": None,
            "total_qty": 2,
            "total_rupiah": 40000,
        },
    ]
    assert (
        client.get("/laporan/produk-terlaris?limit=1", headers=headers).json() == ranking.json()[:1]
    )


def set_finished_at(client, order_id, moment):
    with client.app.state.sessions() as db:
        db.execute(
            update(Pesanan)
            .where(Pesanan.id == UUID(order_id))
            .values(created_at=moment - timedelta(days=90), updated_at=moment)
        )
        db.commit()


@pytest.mark.parametrize("days", [7, 30])
def test_report_uses_completion_time_and_half_open_jakarta_days(
    dev_client, account, monkeypatch, days
):
    client = dev_client
    fixed = datetime(2026, 10, 20, 5, tzinfo=timezone.utc)
    monkeypatch.setattr("app.services.laporan.now_utc", lambda: fixed)
    end = datetime(2026, 10, 20, 17, tzinfo=timezone.utc)
    start = end - timedelta(days=days)
    headers = seller(client, account)
    produk_id = create_product(client, headers, "Beras", 10000)
    moments = [
        start,
        end - timedelta(microseconds=1),
        start - timedelta(microseconds=1),
        start - timedelta(days=days),
        start - timedelta(days=days, microseconds=1),
        end,
    ]
    for moment in moments:
        order_id = create_order(client, headers, [{"produk_id": produk_id, "qty": 1}], "selesai")
        set_finished_at(client, order_id, moment)
    data = client.get(f"/laporan/ringkasan?range={days}h", headers=headers).json()
    assert data["total_penjualan"] == 20000
    assert data["jumlah_pesanan"] == 2
    assert data["jumlah_produk_terjual"] == 2
    assert data["ada_pembanding"] is True
    assert data["perbandingan_minggu_lalu"] == 0.0
    daily = data["penjualan_per_hari"]
    assert len(daily) == days
    assert daily[0] == {"tanggal": (start + timedelta(hours=7)).date().isoformat(), "total": 10000}
    assert daily[-1] == {"tanggal": "2026-10-20", "total": 10000}
    assert all(day["total"] == 0 for day in daily[1:-1])
    ranking = client.get(f"/laporan/produk-terlaris?range={days}h", headers=headers).json()
    assert len(ranking) == 1
    assert ranking[0]["total_qty"] == 2


def test_comparison_uses_previous_period_of_the_same_length(dev_client, account, monkeypatch):
    client = dev_client
    fixed = datetime(2026, 10, 20, 5, tzinfo=timezone.utc)
    monkeypatch.setattr("app.services.laporan.now_utc", lambda: fixed)
    headers = seller(client, account)
    produk_id = create_product(client, headers, "Beras", 10000)
    for days_ago, qty, shipping in [(0, 11, 500), (10, 5, 0), (45, 10, 0)]:
        order_id = create_order(
            client, headers, [{"produk_id": produk_id, "qty": qty}], "selesai", ongkir=shipping
        )
        set_finished_at(client, order_id, fixed - timedelta(days=days_ago))
    week = client.get("/laporan/ringkasan?range=7h", headers=headers).json()
    month = client.get("/laporan/ringkasan?range=30h", headers=headers).json()
    assert week["total_penjualan"] == 110500
    assert week["perbandingan_minggu_lalu"] == 121.0
    assert month["total_penjualan"] == 160500
    assert month["perbandingan_minggu_lalu"] == 60.5
    assert week["jumlah_pesanan"] == 1
    assert month["jumlah_pesanan"] == 2


def test_zero_sales_can_have_a_negative_comparison(dev_client, account, monkeypatch):
    client = dev_client
    fixed = datetime(2026, 10, 20, 5, tzinfo=timezone.utc)
    monkeypatch.setattr("app.services.laporan.now_utc", lambda: fixed)
    headers = seller(client, account)
    produk_id = create_product(client, headers, "Beras", 10000)
    order_id = create_order(client, headers, [{"produk_id": produk_id, "qty": 1}], "selesai")
    set_finished_at(client, order_id, fixed - timedelta(days=10))
    data = client.get("/laporan/ringkasan", headers=headers).json()
    assert data["total_penjualan"] == 0
    assert data["jumlah_pesanan"] == 0
    assert data["perbandingan_minggu_lalu"] == -100.0
    assert data["ada_pembanding"] is True
    assert data["penjualan_per_hari"] == []


def test_fully_discounted_orders_still_have_quantity_and_daily_data(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    produk_id = create_product(client, headers, "Beras", 10000)
    create_order(client, headers, [{"produk_id": produk_id, "qty": 3}], "selesai", diskon=30000)
    data = client.get("/laporan/ringkasan", headers=headers).json()
    assert data["total_penjualan"] == 0
    assert data["jumlah_pesanan"] == 1
    assert data["jumlah_produk_terjual"] == 3
    assert len(data["penjualan_per_hari"]) == 7
    ranking = client.get("/laporan/produk-terlaris", headers=headers).json()
    assert ranking[0]["total_rupiah"] == 30000


def test_ranking_preserves_snapshot_prices_and_deleted_products(dev_client, account):
    client = dev_client
    headers = seller(client, account)
    first = create_product(client, headers, "Beras Lama", 10000)
    second = create_product(client, headers, "Minyak", 12000)
    create_order(client, headers, [{"produk_id": first, "qty": 1}], "selesai")
    assert (
        client.put(
            f"/produk/{first}", headers=headers, json={"nama": "Beras Baru", "harga": 20000}
        ).status_code
        == 200
    )
    create_order(client, headers, [{"produk_id": first, "qty": 2}], "selesai")
    create_order(client, headers, [{"produk_id": second, "qty": 2}], "selesai")
    with client.app.state.sessions() as db:
        db.execute(
            update(Produk).where(Produk.id == UUID(first)).values(foto_url="/uploads/uji.png")
        )
        db.commit()
    rows = client.get("/laporan/produk-terlaris", headers=headers).json()
    assert rows[0] == {
        "produk_id": first,
        "nama": "Beras Baru",
        "foto_url": "/uploads/uji.png",
        "total_qty": 3,
        "total_rupiah": 50000,
    }
    assert client.delete(f"/produk/{first}", headers=headers).status_code == 200
    assert client.delete(f"/produk/{second}", headers=headers).status_code == 200
    rows = client.get("/laporan/produk-terlaris", headers=headers).json()
    assert {row["nama"] for row in rows} == {"Beras Lama", "Beras Baru", "Minyak"}
    assert all(row["produk_id"] is None and row["foto_url"] is None for row in rows)
    assert sum(row["total_qty"] for row in rows) == 5
    assert sum(row["total_rupiah"] for row in rows) == 74000


def test_concurrent_completion_keeps_all_report_totals_in_one_snapshot(pg_client, account):
    client = pg_client
    client.app.state.settings.env = "dev"
    headers = seller(client, account)
    produk_id = create_product(client, headers, "Beras", 10000)
    create_order(client, headers, [{"produk_id": produk_id, "qty": 1}], "selesai")
    pending = create_order(client, headers, [{"produk_id": produk_id, "qty": 2}], "diantar")
    paused, release = Event(), Event()

    def scoped_db(request: Request):
        with client.app.state.sessions() as db:
            info = db.connection().info
            info["a4_report"] = request.url.path.startswith("/laporan/")
            try:
                yield db
            finally:
                info.pop("a4_report", None)

    def after_query(connection, cursor, statement, parameters, context, many):
        if connection.info.get("a4_report") and "sum(" in statement.lower() and not paused.is_set():
            paused.set()
            assert release.wait(5)

    client.app.dependency_overrides[get_db] = scoped_db
    event.listen(client.app.state.engine, "after_cursor_execute", after_query)
    try:
        with ThreadPoolExecutor(max_workers=1) as pool:
            report = pool.submit(client.get, "/laporan/ringkasan", headers=headers)
            try:
                assert paused.wait(5)
                response = client.patch(
                    f"/pesanan/{pending}/status", headers=headers, json={"status": "selesai"}
                )
                assert response.status_code == 200
            finally:
                release.set()
            response = report.result(timeout=5)
        assert response.status_code == 200
        data = response.json()
        assert data["total_penjualan"] == 10000
        assert data["jumlah_pesanan"] == 1
        assert data["jumlah_produk_terjual"] == 1
        assert sum(day["total"] for day in data["penjualan_per_hari"]) == data["total_penjualan"]
    finally:
        release.set()
        event.remove(client.app.state.engine, "after_cursor_execute", after_query)
        client.app.dependency_overrides.pop(get_db, None)

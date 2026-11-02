from datetime import datetime, time, timedelta, timezone

from sqlalchemy import func, select, true

from app.models.pesanan import Pesanan, PesananItem
from app.models.produk import Produk
from app.models.user import now_utc
from app.schemas.laporan import RingkasanLaporan

WIB = timezone(timedelta(hours=7))


def report_window(periode):
    days = 7 if periode == "7h" else 30
    tomorrow = now_utc().astimezone(WIB).date() + timedelta(days=1)
    end = datetime.combine(tomorrow, time.min, WIB).astimezone(timezone.utc)
    return end - timedelta(days=days), end, days


def completed(toko_id, start, end):
    return (
        Pesanan.toko_id == toko_id,
        Pesanan.status == "selesai",
        Pesanan.updated_at >= start,
        Pesanan.updated_at < end,
    )


def sales_for_window(toko_id, start, end, days):
    orders = (
        select(Pesanan.id, Pesanan.updated_at, Pesanan.total)
        .where(*completed(toko_id, start - timedelta(days=days), end))
        .cte("pesanan_selesai")
    )
    quantities = (
        select(PesananItem.pesanan_id, func.sum(PesananItem.qty).label("qty"))
        .join(orders, orders.c.id == PesananItem.pesanan_id)
        .group_by(PesananItem.pesanan_id)
        .cte("jumlah_barang")
    )
    return (
        select(orders.c.updated_at, orders.c.total, func.coalesce(quantities.c.qty, 0).label("qty"))
        .select_from(orders)
        .outerjoin(quantities, quantities.c.pesanan_id == orders.c.id)
        .cte("penjualan")
    )


def order_totals(sales, start):
    current = sales.c.updated_at >= start
    return select(
        func.coalesce(func.sum(sales.c.total).filter(current), 0).label("total"),
        func.count().filter(current).label("jumlah"),
        func.coalesce(func.sum(sales.c.qty).filter(current), 0).label("qty"),
        func.coalesce(func.sum(sales.c.total).filter(sales.c.updated_at < start), 0).label(
            "previous"
        ),
    ).cte("ringkasan")


def daily_sales(db, sales, start):
    local_day = (
        func.date(func.timezone("Asia/Jakarta", sales.c.updated_at))
        if db.bind.dialect.name == "postgresql"
        # SQLite menghitung tanggal lewat bilangan Julian (float): nilai
        # 23:59:59.999999 + 7 jam bisa membulat jadi tengah malam berikut.
        # Potong mikrodetik dulu (substr 19 karakter pertama = detik) supaya
        # pengelompokan hari tidak pernah meleset satu hari.
        else func.date(func.substr(sales.c.updated_at, 1, 19), "+7 hours")
    )
    return (
        select(local_day.label("tanggal"), func.sum(sales.c.total).label("harian"))
        .where(sales.c.updated_at >= start)
        .group_by(local_day)
        .cte("harian")
    )


def summary(db, toko_id, periode):
    start, end, days = report_window(periode)
    sales = sales_for_window(toko_id, start, end, days)
    totals, daily = order_totals(sales, start), daily_sales(db, sales, start)
    rows = db.execute(
        select(*totals.c, daily.c.tanggal, daily.c.harian)
        .select_from(totals)
        .outerjoin(daily, true())
        .order_by(daily.c.tanggal)
    ).all()
    first = rows[0]
    daily_totals = {str(row.tanggal): row.harian for row in rows if row.tanggal is not None}
    first_day = start.astimezone(WIB).date()
    dates = [first_day + timedelta(days=i) for i in range(days)] if first.jumlah else []
    return RingkasanLaporan(
        total_penjualan=first.total,
        jumlah_pesanan=first.jumlah,
        jumlah_produk_terjual=first.qty,
        perbandingan_minggu_lalu=round((first.total - first.previous) * 100 / first.previous, 2)
        if first.previous
        else 0.0,
        ada_pembanding=first.previous > 0,
        penjualan_per_hari=[
            {"tanggal": day, "total": daily_totals.get(day.isoformat(), 0)} for day in dates
        ],
    )


def best_products(db, toko_id, periode, limit):
    start, end, _ = report_window(periode)
    nama = func.coalesce(Produk.nama, PesananItem.nama_snapshot)
    qty = func.sum(PesananItem.qty)
    rupiah = func.sum(PesananItem.harga_snapshot * PesananItem.qty)
    query = (
        select(
            Produk.id.label("produk_id"),
            nama.label("nama"),
            Produk.foto_url,
            qty.label("total_qty"),
            rupiah.label("total_rupiah"),
        )
        .select_from(PesananItem)
        .join(Pesanan, Pesanan.id == PesananItem.pesanan_id)
        .outerjoin(Produk, Produk.id == PesananItem.produk_id)
        .where(*completed(toko_id, start, end))
        .group_by(Produk.id, nama, Produk.foto_url)
        .order_by(qty.desc(), rupiah.desc(), nama, Produk.id)
        .limit(limit)
    )
    return db.execute(query).mappings().all()

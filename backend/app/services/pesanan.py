import secrets

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan, PesananItem
from app.models.produk import Produk
from app.models.user import now_utc
from app.schemas.pesanan import ItemTest
from app.services.pembayaran import release_stock


def snapshot_items(db, toko_id, requested):
    query = select(Produk).where(Produk.toko_id == toko_id).order_by(Produk.id).with_for_update()
    if requested is not None:
        ids = [item.produk_id for item in requested]
        if len(set(ids)) != len(ids):
            raise HTTPException(422, "Produk tidak boleh berulang")
        query = query.where(Produk.id.in_(ids))
    else:
        query = query.limit(1)
    products = {produk.id: produk for produk in db.scalars(query)}
    if requested is None:
        if not products:
            raise HTTPException(422, "Tambahkan produk sebelum membuat pesanan uji")
        requested = [ItemTest(produk_id=next(iter(products)), qty=1)]
    if any(item.produk_id not in products for item in requested):
        raise HTTPException(404, "Produk tidak ditemukan")
    return [
        dict(
            produk_id=item.produk_id,
            nama_snapshot=products[item.produk_id].nama,
            harga_snapshot=products[item.produk_id].harga,
            qty=item.qty,
        )
        for item in requested
    ]


def create_test_order(db, toko_id, data):
    items = snapshot_items(db, toko_id, data.items)
    subtotal = sum(item["harga_snapshot"] * item["qty"] for item in items)
    total = subtotal - data.diskon + data.ongkir + data.biaya_layanan
    if data.diskon > subtotal or not 0 <= total <= 2147483647 or subtotal > 2147483647:
        raise HTTPException(422, "Jumlah biaya pesanan tidak valid")
    fields = data.model_dump(exclude={"items"})
    for _ in range(5):
        kode = f"DG-{10000 + secrets.randbelow(90000):05}"
        try:
            with db.begin_nested():
                pesanan = Pesanan(
                    kode=kode,
                    toko_id=toko_id,
                    subtotal=subtotal,
                    total=total,
                    items=[PesananItem(**item) for item in items],
                    **fields,
                )
                db.add(pesanan)
                db.flush()
            db.commit()
            return pesanan
        except IntegrityError:
            if not db.scalar(select(Pesanan.id).where(Pesanan.kode == kode)):
                raise
    raise HTTPException(503, "Kode pesanan belum dapat dibuat. Coba lagi.")


def transition(db, pesanan, action, reason=None):
    payment = db.scalar(
        select(Pembayaran)
        .where(Pembayaran.pesanan_id == pesanan.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if (
        payment
        and payment.metode != "cod"
        and payment.status != "paid"
        and action not in {"ditolak", "dibatalkan"}
    ):
        raise HTTPException(400, "Pesanan belum dibayar")
    status = pesanan.status
    terminal = status in ("selesai", "dibatalkan", "ditolak")
    next_status = {
        "baru": "diproses",
        "diproses": "dikemas",
        "dikemas": "diantar",
        "diantar": "selesai",
    }.get(status)
    now = now_utc()
    if action == "urungkan":
        if status != "diproses" or pesanan.undo_until is None or now >= pesanan.undo_until:
            raise HTTPException(
                400, "Pesanan tidak dapat diurungkan setelah 10 detik atau status berubah"
            )
        pesanan.status, pesanan.accepted_at = "baru", None
    elif action == "ditolak" and reason is not None and status == "baru":
        pesanan.status, pesanan.tolak_alasan = "ditolak", reason
    elif not terminal and (action == next_status or action == "dibatalkan"):
        pesanan.status = action
        if action == "diproses":
            pesanan.accepted_at = now
    else:
        raise HTTPException(400, "Urutan status pesanan tidak valid")
    if payment and pesanan.status in {"ditolak", "dibatalkan"}:
        release_stock(db, pesanan, payment)
        if payment.status == "paid":
            payment.perlu_rekonsiliasi = True
        if payment.status == "pending":
            payment.status = "failed"
    db.commit()
    return pesanan

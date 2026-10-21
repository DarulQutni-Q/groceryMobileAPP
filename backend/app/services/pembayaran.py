from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan
from app.models.produk import Produk
from app.models.user import now_utc


def release_stock(db, order, payment):
    if not payment.stok_direservasi:
        return
    quantities = {item.produk_id: item.qty for item in order.items if item.produk_id}
    products = db.scalars(
        select(Produk).where(Produk.id.in_(quantities)).order_by(Produk.id).with_for_update()
    ).all()
    for product in products:
        if product.stok + quantities[product.id] > 2147483647:
            raise HTTPException(409, "Stok melebihi batas, periksa inventaris terlebih dahulu")
        product.stok += quantities[product.id]
    payment.stok_direservasi = False


def apply_invoice(db, event):
    payment = db.scalar(select(Pembayaran).where(Pembayaran.xendit_id == event.id))
    if payment is None:
        raise HTTPException(404, "Pembayaran tidak ditemukan")
    order = db.scalar(
        select(Pesanan)
        .where(Pesanan.id == payment.pesanan_id)
        .options(selectinload(Pesanan.items))
        .with_for_update()
    )
    payment = db.scalar(
        select(Pembayaran)
        .where(Pembayaran.id == payment.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if event.external_id != payment.external_id or event.amount != payment.jumlah:
        raise HTTPException(400, "Identitas atau nominal pembayaran tidak sesuai")
    if event.paid_amount is not None and event.status in {"PAID", "SETTLED"}:
        if event.paid_amount < payment.jumlah:
            raise HTTPException(400, "Nominal pembayaran belum mencukupi tagihan")
    if payment.status == "paid":
        return payment
    if event.status in {"PAID", "SETTLED"}:
        if not payment.stok_direservasi or order.status in {"dibatalkan", "ditolak"}:
            raise HTTPException(409, "Pembayaran pesanan batal perlu rekonsiliasi")
        payment.status, payment.paid_at = "paid", event.paid_at or now_utc()
    elif event.status in {"EXPIRED", "FAILED"} and payment.status == "pending":
        payment.status = event.status.lower()
        order.status = "dibatalkan"
        release_stock(db, order, payment)
    db.commit()
    return payment

import hashlib
import json
import secrets
import time

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import selectinload

from app.models.checkout_attempt import CheckoutAttempt
from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan, PesananItem
from app.models.produk import Produk
from app.models.toko import Toko
from app.models.user import now_utc
from app.schemas.pembayaran import CheckoutResponse, InvoiceEvent
from app.services.alamat import lock_customer, owned_address
from app.services.fcm import notify_order_owner
from app.services.notifikasi import catat_pesanan_baru
from app.services.voucher import terapkan_voucher
from app.services.xendit import safe_payment_url


def locked_catalog(db, data):
    ids = [item.produk_id for item in data.items]
    store_ids = set(db.scalars(select(Produk.toko_id).where(Produk.id.in_(ids))))
    if len(store_ids) != 1:
        raise HTTPException(400, "Produk harus tersedia dan berasal dari satu toko")
    store = db.scalar(
        select(Toko)
        .where(Toko.id.in_(store_ids))
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if store is None or store.status != "buka":
        raise HTTPException(400, "Toko sedang tutup")
    products = {
        p.id: p
        for p in db.scalars(
            select(Produk)
            .where(Produk.id.in_(ids))
            .order_by(Produk.id)
            .with_for_update()
            .execution_options(populate_existing=True)
        )
    }
    return store, products


def quote(db, user, data):
    address = owned_address(db, user, data.alamat_id)
    store, products = locked_catalog(db, data)
    items = []
    for item in data.items:
        product = products.get(item.produk_id)
        if product is None or not product.is_tersedia:
            raise HTTPException(400, "Produk tidak ditemukan atau tidak tersedia")
        if item.qty > product.stok:
            raise HTTPException(400, f"Stok {product.nama} tidak cukup, sisa {product.stok}")
        items.append(
            dict(
                produk_id=product.id,
                nama_snapshot=product.nama,
                harga_snapshot=product.harga,
                qty=item.qty,
            )
        )
    subtotal = sum(i["harga_snapshot"] * i["qty"] for i in items)
    if subtotal + 1000 > 2147483647:
        raise HTTPException(422, "Total tagihan melebihi batas pembayaran")
    diskon = 0
    ongkir = 0
    voucher_kode = None
    if data.voucher_kode:
        voucher, diskon, potongan_ongkir = terapkan_voucher(
            db, store.id, data.voucher_kode, subtotal, ongkir
        )
        ongkir -= potongan_ongkir
        voucher_kode = voucher.kode
    costs = dict(
        subtotal=subtotal,
        diskon=diskon,
        ongkir=ongkir,
        biaya_layanan=1000,
        total=subtotal - diskon + ongkir + 1000,
        voucher_kode=voucher_kode,
    )
    if data.total_dikonfirmasi is not None and data.total_dikonfirmasi != costs["total"]:
        raise HTTPException(409, "Harga berubah. Periksa rincian biaya sebelum membayar")
    return address, store, products, items, costs


def checkout_result(db, payment):
    order = db.scalar(
        select(Pesanan)
        .where(Pesanan.id == payment.pesanan_id)
        .options(selectinload(Pesanan.items), selectinload(Pesanan.customer))
    )
    return CheckoutResponse(pesanan=order, pembayaran=payment, payment_url=payment.payment_url)


def prepare_attempt(db, user, data, key, gateway):
    lock_customer(db, user)
    fingerprint = hashlib.sha256(
        json.dumps(data.model_dump(mode="json"), sort_keys=True).encode()
    ).hexdigest()
    attempt = db.scalar(select(CheckoutAttempt).where(CheckoutAttempt.request_key == key))
    if attempt:
        if attempt.user_id != user.id or attempt.fingerprint != fingerprint:
            raise HTTPException(409, "Kunci checkout sudah dipakai untuk permintaan lain")
        payment = db.scalar(select(Pembayaran).where(Pembayaran.external_id == attempt.external_id))
        return attempt, payment, False
    try:
        costs = quote(db, user, data)[-1]
        if data.metode_bayar != "cod":
            gateway.available()
    except HTTPException as exc:
        exc.headers = {**(exc.headers or {}), "X-Checkout-Started": "false"}
        raise
    attempt = CheckoutAttempt(
        request_key=key,
        user_id=user.id,
        fingerprint=fingerprint,
        external_id="GM-" + key,
        jumlah=costs["total"],
    )
    db.add(attempt)
    db.commit()
    return attempt, None, True


def invoice_for(attempt, user, data, gateway, fresh):
    if data.metode_bayar == "cod":
        return None
    invoice = (
        gateway.create_invoice(
            attempt.external_id, attempt.jumlah, user.email, "Belanja GardenMart"
        )
        if fresh
        else gateway.find_invoice(attempt.external_id)
    )
    try:
        event = InvoiceEvent.model_validate(invoice)
    except ValueError:
        raise HTTPException(502, "Respons invoice Xendit tidak valid") from None
    if (
        event.external_id != attempt.external_id
        or event.amount != attempt.jumlah
        or event.status not in {"PENDING", "PAID", "SETTLED"}
        or (
            event.paid_amount is not None
            and event.status in {"PAID", "SETTLED"}
            and event.paid_amount < attempt.jumlah
        )
    ):
        raise HTTPException(409, "Invoice perlu diperiksa sebelum membuat pesanan")
    return event, safe_payment_url(invoice.get("invoice_url"))


def insert_order(db, user, data, address, store, items, costs):
    for _ in range(5):
        code = f"DG-{10000 + secrets.randbelow(90000):05}"
        if db.scalar(select(Pesanan.id).where(Pesanan.kode == code)):
            continue
        order = Pesanan(
            kode=code,
            customer_id=user.id,
            customer=user,
            toko_id=store.id,
            alamat_kirim="\n".join(
                filter(
                    None,
                    [address.nama_penerima, address.no_hp, address.alamat_lengkap, address.patokan],
                )
            ),
            catatan=data.catatan,
            metode_kirim=data.metode_kirim,
            slot_waktu="Segera",
            items=[PesananItem(**item) for item in items],
            **costs,
        )
        db.add(order)
        db.flush()
        return order
    raise HTTPException(503, "Kode pesanan belum dapat dibuat, coba lagi")


def merge_invoice(db, attempt, invoice):
    attempt = db.scalar(
        select(CheckoutAttempt)
        .where(CheckoutAttempt.id == attempt.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if invoice and attempt.xendit_id and attempt.xendit_id != invoice[0].id:
        raise HTTPException(409, "Identitas invoice berubah, pembayaran perlu diperiksa")
    if invoice and attempt.remote_status in {"EXPIRED", "FAILED"}:
        raise HTTPException(409, "Invoice sudah berakhir, pembayaran perlu diperiksa")
    if invoice and attempt.remote_status in {"PAID", "SETTLED"}:
        invoice = (invoice[0].model_copy(update={"status": attempt.remote_status}), invoice[1])
    return invoice


def reserve_payment(db, order, data, attempt, invoice, products):
    payment = Pembayaran(
        pesanan_id=order.id,
        external_id=attempt.external_id,
        metode=data.metode_bayar,
        jumlah=attempt.jumlah,
        xendit_id=invoice[0].id if invoice else None,
        payment_url=invoice[1] if invoice else None,
    )
    if invoice:
        attempt.xendit_id, attempt.remote_status = invoice[0].id, invoice[0].status
        attempt.perlu_rekonsiliasi = False
        if invoice[0].status in {"PAID", "SETTLED"}:
            payment.status = "paid"
            payment.paid_at = invoice[0].paid_at or now_utc()
    db.add(payment)
    for item in data.items:
        products[item.produk_id].stok -= item.qty
    return payment


def finalize_order(db, user, data, attempt, gateway, fresh, settings=None):
    lock_customer(db, user)
    payment = db.scalar(select(Pembayaran).where(Pembayaran.external_id == attempt.external_id))
    if payment:
        return checkout_result(db, payment)
    try:
        address, store, products, items, costs = quote(db, user, data)
        if costs["total"] != attempt.jumlah:
            raise HTTPException(409, "Harga berubah, invoice lama perlu diperiksa")
    except HTTPException as exc:
        if fresh:
            exc.headers = {**(exc.headers or {}), "X-Checkout-Started": "false"}
        raise
    invoice = merge_invoice(db, attempt, invoice_for(attempt, user, data, gateway, fresh))
    order = insert_order(db, user, data, address, store, items, costs)
    payment = reserve_payment(db, order, data, attempt, invoice, products)
    catat_pesanan_baru(db, order, store)
    db.commit()
    if settings is not None:
        notify_order_owner(db, order, store, settings)
    return checkout_result(db, payment)


def perform_checkout(db, user, data, key, gateway, settings=None):
    key = key or f"{int(time.time() * 1000)}-{secrets.token_hex(16)}"
    try:
        attempt, payment, fresh = prepare_attempt(db, user, data, key, gateway)
        if payment:
            return checkout_result(db, payment)
        return finalize_order(db, user, data, attempt, gateway, fresh, settings)
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            503, "Checkout belum dapat disimpan, periksa lagi dengan kunci yang sama"
        ) from None
    except Exception:
        db.rollback()
        raise

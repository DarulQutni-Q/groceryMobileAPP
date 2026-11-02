import secrets
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from limits import parse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.rate_limit import check_limit
from app.db.session import get_db
from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan
from app.models.user import User
from app.schemas.pembayaran import CheckoutInput, CheckoutResponse, InvoiceEvent, PembayaranResponse
from app.services.alamat import get_customer
from app.services.checkout import perform_checkout, quote
from app.services.pembayaran import apply_invoice, reconcile_with_xendit
from app.services.xendit import get_gateway

router = APIRouter(tags=["Pembayaran"])
Key = Annotated[str | None, Header(pattern=r"^[0-9]{13}-[a-f0-9]{32}$")]


@router.post("/checkout/preview")
def preview(data: CheckoutInput, user: User = Depends(get_customer), db: Session = Depends(get_db)):
    *_, items, costs = quote(db, user, data)
    return {**costs, "items": items}


@router.post("/checkout", response_model=CheckoutResponse, status_code=201)
def checkout(
    data: CheckoutInput,
    request: Request,
    idempotency_key: Key = None,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
    gateway=Depends(get_gateway),
):
    check_limit(request, parse("10/minute"), "checkout", str(user.id))
    return perform_checkout(
        db,
        user,
        data,
        idempotency_key,
        gateway(data.metode_bayar),
        settings=request.app.state.settings,
    )


def verify_callback(request: Request, x_callback_token: Annotated[str | None, Header()] = None):
    expected = request.app.state.settings.xendit_webhook_token.get_secret_value()
    if (
        not expected
        or not x_callback_token
        or not secrets.compare_digest(expected.encode(), x_callback_token.encode())
    ):
        raise HTTPException(403, "Token webhook tidak valid")


@router.post("/webhook/xendit", dependencies=[Depends(verify_callback)])
def webhook(event: InvoiceEvent, db: Session = Depends(get_db)):
    payment = apply_invoice(db, event)
    return {"status": payment.status}


@router.get("/pembayaran/{payment_id}/status", response_model=PembayaranResponse)
def status(
    payment_id: UUID,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
    gateway=Depends(get_gateway),
):
    payment = db.get(Pembayaran, payment_id)
    if payment is None:
        raise HTTPException(404, "Pembayaran tidak ditemukan")
    owner = db.scalar(select(Pesanan.customer_id).where(Pesanan.id == payment.pesanan_id))
    if owner != user.id:
        raise HTTPException(403, "Pembayaran bukan milik akun ini")
    return reconcile_with_xendit(db, payment, gateway)

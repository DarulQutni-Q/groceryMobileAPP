from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.core.security import get_authenticated_user
from app.db.session import get_db
from app.models.pesanan import TAB_STATUS, Pesanan
from app.models.toko import Toko
from app.models.user import User
from app.schemas.pagination import Page
from app.schemas.pesanan import PesananResponse, PesananTest, StatusRequest, TolakRequest
from app.services.pagination import Pagination, list_response, pagination_params
from app.services.pesanan import create_test_order, transition
from app.services.fcm import notify_order_customer
from app.services.toko import get_store

router = APIRouter(prefix="/pesanan", tags=["Pesanan"])


def require_dev(request: Request):
    if request.app.state.settings.env != "dev":
        raise HTTPException(404, "Tidak ditemukan")


def get_pesanan(pesanan_id: UUID, toko: Toko = Depends(get_store), db: Session = Depends(get_db)):
    pesanan = db.scalar(
        select(Pesanan)
        .where(Pesanan.id == pesanan_id, Pesanan.toko_id == toko.id)
        .options(selectinload(Pesanan.items), selectinload(Pesanan.customer))
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if pesanan is None:
        raise HTTPException(404, "Pesanan tidak ditemukan")
    return pesanan


@router.post("/internal/test", response_model=PesananResponse, dependencies=[Depends(require_dev)])
def test_order(
    data: PesananTest = PesananTest(),
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    return create_test_order(db, toko.id, data)


@router.get("", response_model=list[PesananResponse] | Page[PesananResponse])
def listing(
    status: Literal["baru", "diproses", "selesai"] | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    user: User = Depends(get_authenticated_user),
    db: Session = Depends(get_db),
):
    if user.role == "customer":
        query = select(Pesanan).where(Pesanan.customer_id == user.id)
        pagination = pagination or Pagination(1, 20)
    else:
        toko = get_store(user)
        query = select(Pesanan).where(Pesanan.toko_id == toko.id)
    if status is not None:
        query = query.where(Pesanan.status.in_(TAB_STATUS[status]))
    query = query.options(joinedload(Pesanan.items), joinedload(Pesanan.customer)).order_by(
        Pesanan.created_at.desc(), Pesanan.id
    )
    return list_response(db, query, pagination)


@router.get("/{pesanan_id}", response_model=PesananResponse)
def detail(
    pesanan_id: UUID, user: User = Depends(get_authenticated_user), db: Session = Depends(get_db)
):
    if user.role == "seller":
        return get_pesanan(pesanan_id, get_store(user), db)
    order = db.scalar(
        select(Pesanan)
        .where(Pesanan.id == pesanan_id, Pesanan.customer_id == user.id)
        .options(selectinload(Pesanan.items), selectinload(Pesanan.customer))
    )
    if order is None:
        raise HTTPException(404, "Pesanan tidak ditemukan")
    return order


@router.patch("/{pesanan_id}/terima", response_model=PesananResponse)
def accept(
    request: Request,
    pesanan: Pesanan = Depends(get_pesanan),
    db: Session = Depends(get_db),
):
    result = transition(db, pesanan, "diproses")
    notify_order_customer(db, result, request.app.state.settings)
    return result


@router.patch("/{pesanan_id}/tolak", response_model=PesananResponse)
def reject(
    data: TolakRequest,
    request: Request,
    pesanan: Pesanan = Depends(get_pesanan),
    db: Session = Depends(get_db),
):
    result = transition(db, pesanan, "ditolak", data.alasan)
    notify_order_customer(db, result, request.app.state.settings)
    return result


@router.patch("/{pesanan_id}/status", response_model=PesananResponse)
def status(
    data: StatusRequest,
    request: Request,
    pesanan: Pesanan = Depends(get_pesanan),
    db: Session = Depends(get_db),
):
    result = transition(db, pesanan, data.status)
    notify_order_customer(db, result, request.app.state.settings)
    return result


@router.patch("/{pesanan_id}/urungkan", response_model=PesananResponse)
def undo(
    request: Request,
    pesanan: Pesanan = Depends(get_pesanan),
    db: Session = Depends(get_db),
):
    result = transition(db, pesanan, "urungkan")
    notify_order_customer(db, result, request.app.state.settings)
    return result

from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.db.session import get_db
from app.models.pesanan import TAB_STATUS, Pesanan
from app.models.toko import Toko
from app.schemas.pagination import Page
from app.schemas.pesanan import PesananResponse, PesananTest, StatusRequest, TolakRequest
from app.services.pagination import Pagination, list_response, pagination_params
from app.services.pesanan import create_test_order, transition
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
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    query = select(Pesanan).where(Pesanan.toko_id == toko.id)
    if status is not None:
        query = query.where(Pesanan.status.in_(TAB_STATUS[status]))
    query = query.options(joinedload(Pesanan.items), joinedload(Pesanan.customer)).order_by(
        Pesanan.created_at.desc(), Pesanan.id
    )
    return list_response(db, query, pagination)


@router.get("/{pesanan_id}", response_model=PesananResponse)
def detail(pesanan: Pesanan = Depends(get_pesanan)):
    return pesanan


@router.patch("/{pesanan_id}/terima", response_model=PesananResponse)
def accept(pesanan: Pesanan = Depends(get_pesanan), db: Session = Depends(get_db)):
    return transition(db, pesanan, "diproses")


@router.patch("/{pesanan_id}/tolak", response_model=PesananResponse)
def reject(
    data: TolakRequest, pesanan: Pesanan = Depends(get_pesanan), db: Session = Depends(get_db)
):
    return transition(db, pesanan, "ditolak", data.alasan)


@router.patch("/{pesanan_id}/status", response_model=PesananResponse)
def status(
    data: StatusRequest, pesanan: Pesanan = Depends(get_pesanan), db: Session = Depends(get_db)
):
    return transition(db, pesanan, data.status)


@router.patch("/{pesanan_id}/urungkan", response_model=PesananResponse)
def undo(pesanan: Pesanan = Depends(get_pesanan), db: Session = Depends(get_db)):
    return transition(db, pesanan, "urungkan")

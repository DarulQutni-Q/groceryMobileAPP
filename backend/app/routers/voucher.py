from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import get_authenticated_user
from app.db.session import get_db
from app.models.toko import Toko
from app.models.user import User
from app.models.voucher import Voucher
from app.schemas.voucher import VoucherCreate, VoucherResponse, VoucherUpdate
from app.services.alamat import get_customer
from app.services.toko import get_store

router = APIRouter(prefix="/voucher", tags=["Voucher"])


@router.post("", response_model=VoucherResponse, status_code=201)
def buat_voucher(
    data: VoucherCreate,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    voucher = Voucher(toko_id=toko.id, **data.model_dump())
    db.add(voucher)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(400, "Kode voucher sudah dipakai di toko ini")
    db.refresh(voucher)
    return voucher


@router.get("", response_model=list[VoucherResponse])
def daftar_voucher_toko(
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(Voucher).where(Voucher.toko_id == toko.id).order_by(Voucher.created_at)
        )
    )


@router.get("/toko/{toko_id}", response_model=list[VoucherResponse])
def daftar_voucher_customer(
    toko_id: UUID,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(Voucher)
            .where(Voucher.toko_id == toko_id, Voucher.aktif.is_(True))
            .order_by(Voucher.created_at)
        )
    )


@router.patch("/{voucher_id}", response_model=VoucherResponse)
def ubah_voucher(
    voucher_id: UUID,
    data: VoucherUpdate,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    voucher = db.scalar(
        select(Voucher).where(Voucher.id == voucher_id, Voucher.toko_id == toko.id)
    )
    if voucher is None:
        raise HTTPException(404, "Voucher tidak ditemukan")
    voucher.aktif = data.aktif
    db.commit()
    db.refresh(voucher)
    return voucher


@router.delete("/{voucher_id}", status_code=204)
def hapus_voucher(
    voucher_id: UUID,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    voucher = db.scalar(
        select(Voucher).where(Voucher.id == voucher_id, Voucher.toko_id == toko.id)
    )
    if voucher is None:
        raise HTTPException(404, "Voucher tidak ditemukan")
    db.delete(voucher)
    db.commit()
    return None

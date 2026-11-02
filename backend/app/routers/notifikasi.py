from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.security import get_authenticated_user
from app.db.session import get_db
from app.models.notifikasi import Notifikasi
from app.models.user import User
from app.schemas.notifikasi import NotifikasiListResponse, NotifikasiResponse

router = APIRouter(prefix="/notifikasi", tags=["Notifikasi"])


@router.get("", response_model=NotifikasiListResponse)
def listing(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user: User = Depends(get_authenticated_user),
    db: Session = Depends(get_db),
):
    rows = db.scalars(
        select(Notifikasi)
        .where(Notifikasi.user_id == user.id)
        .order_by(Notifikasi.created_at.desc(), Notifikasi.id.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    belum = (
        db.scalar(
            select(func.count())
            .select_from(Notifikasi)
            .where(Notifikasi.user_id == user.id, Notifikasi.dibaca == False)  # noqa: E712
        )
        or 0
    )
    return NotifikasiListResponse(
        data=[NotifikasiResponse.model_validate(row) for row in rows],
        belum_dibaca=belum,
    )


def _own(db: Session, user: User, notifikasi_id: UUID):
    row = db.scalar(
        select(Notifikasi).where(
            Notifikasi.id == notifikasi_id, Notifikasi.user_id == user.id
        )
    )
    if row is None:
        raise HTTPException(404, "Notifikasi tidak ditemukan")
    return row


@router.patch("/baca-semua", response_model=dict)
def baca_semua(
    user: User = Depends(get_authenticated_user), db: Session = Depends(get_db)
):
    rows = db.scalars(
        select(Notifikasi).where(
            Notifikasi.user_id == user.id, Notifikasi.dibaca == False  # noqa: E712
        )
    ).all()
    for row in rows:
        row.dibaca = True
    db.commit()
    return {"dibaca": len(rows)}


@router.patch("/{notifikasi_id}/baca", response_model=NotifikasiResponse)
def baca(
    notifikasi_id: UUID,
    user: User = Depends(get_authenticated_user),
    db: Session = Depends(get_db),
):
    row = _own(db, user, notifikasi_id)
    row.dibaca = True
    db.commit()
    return row

from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.models.jam_buka import HARI, JamBuka
from app.models.toko import Toko
from app.models.user import User


def create_store(user: User, db: Session) -> Toko:
    db.flush()
    toko = Toko(
        owner_id=user.id,
        nama=user.nama_toko or f"Toko {user.nama}"[:120],
        telepon=user.phone or "",
    )
    db.add(toko)
    db.flush()
    db.add_all(JamBuka(toko_id=toko.id, hari=hari, is_tutup=True) for hari in HARI)
    return toko


def get_store(user: User = Depends(get_current_user)) -> Toko:
    if user.toko is None:
        raise HTTPException(404, "Toko belum ditemukan")
    return user.toko

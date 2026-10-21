from uuid import UUID

from fastapi import Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.security import get_authenticated_user
from app.models.alamat import Alamat
from app.models.user import User


def get_customer(user: User = Depends(get_authenticated_user)) -> User:
    if user.role != "customer":
        raise HTTPException(403, "Fitur ini khusus akun customer")
    return user


def lock_customer(db: Session, user: User):
    db.scalar(select(User).where(User.id == user.id).with_for_update())


def owned_address(db: Session, user: User, address_id: UUID) -> Alamat:
    address = db.get(Alamat, address_id, populate_existing=True)
    if address is None:
        raise HTTPException(404, "Alamat tidak ditemukan")
    if address.user_id != user.id:
        raise HTTPException(403, "Alamat bukan milik akun ini")
    return address


def set_primary(db: Session, user: User, address: Alamat):
    db.execute(update(Alamat).where(Alamat.user_id == user.id).values(is_utama=False))
    address.is_utama = True

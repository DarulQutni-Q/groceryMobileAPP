from uuid import UUID

from fastapi import APIRouter, Depends, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.alamat import Alamat
from app.models.user import User
from app.schemas.alamat import AlamatInput, AlamatResponse
from app.services.alamat import get_customer, lock_customer, owned_address, set_primary

router = APIRouter(prefix="/alamat", tags=["Alamat"])


@router.get("", response_model=list[AlamatResponse])
def list_addresses(user: User = Depends(get_customer), db: Session = Depends(get_db)):
    return db.scalars(
        select(Alamat)
        .where(Alamat.user_id == user.id)
        .order_by(Alamat.is_utama.desc(), Alamat.created_at, Alamat.id)
    ).all()


@router.post("", status_code=201, response_model=AlamatResponse)
def create_address(
    data: AlamatInput, user: User = Depends(get_customer), db: Session = Depends(get_db)
):
    lock_customer(db, user)
    first = db.scalar(select(Alamat.id).where(Alamat.user_id == user.id)) is None
    address = Alamat(user_id=user.id, **data.model_dump())
    db.add(address)
    if data.is_utama or first:
        set_primary(db, user, address)
    db.commit()
    return address


@router.put("/{address_id}", response_model=AlamatResponse)
def update_address(
    address_id: UUID,
    data: AlamatInput,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    lock_customer(db, user)
    address = owned_address(db, user, address_id)
    was_primary = address.is_utama
    for field, value in data.model_dump(exclude={"is_utama"}).items():
        setattr(address, field, value)
    if data.is_utama or was_primary:
        set_primary(db, user, address)
    db.commit()
    return address


@router.delete("/{address_id}", status_code=204)
def delete_address(
    address_id: UUID, user: User = Depends(get_customer), db: Session = Depends(get_db)
):
    lock_customer(db, user)
    address = owned_address(db, user, address_id)
    primary = address.is_utama
    db.delete(address)
    db.flush()
    if primary:
        following = db.scalar(
            select(Alamat)
            .where(Alamat.user_id == user.id)
            .order_by(Alamat.created_at, Alamat.id)
            .limit(1)
        )
        if following:
            following.is_utama = True
    db.commit()
    return Response(status_code=204)


@router.patch("/{address_id}/jadikan-utama", response_model=AlamatResponse)
def primary_address(
    address_id: UUID, user: User = Depends(get_customer), db: Session = Depends(get_db)
):
    lock_customer(db, user)
    address = owned_address(db, user, address_id)
    set_primary(db, user, address)
    db.commit()
    return address

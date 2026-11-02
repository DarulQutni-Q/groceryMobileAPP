from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.promo import Promo
from app.models.produk import Produk
from app.models.toko import Toko
from app.models.user import now_utc
from app.models.user import User
from app.schemas.promo import PromoCreate, PromoResponse, PromoUpdate
from app.services.alamat import get_customer
from app.services.promo import promo_aktif
from app.services.toko import get_store

router = APIRouter(prefix="/promo", tags=["Promo"])


def _lengkapi(db: Session, promo: Promo):
    data = PromoResponse.model_validate(promo)
    produk = (
        db.scalar(select(Produk).where(Produk.id == promo.produk_id))
        if promo.produk_id
        else None
    )
    toko = db.scalar(select(Toko).where(Toko.id == promo.toko_id))
    data.produk = produk
    data.toko_nama = toko.nama if toko else None
    return data


@router.post("", response_model=PromoResponse, status_code=201)
def buat_promo(
    data: PromoCreate,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    promo = Promo(toko_id=toko.id, **data.model_dump())
    db.add(promo)
    db.commit()
    db.refresh(promo)
    return _lengkapi(db, promo)


@router.get("", response_model=list[PromoResponse])
def daftar_promo_toko(
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    rows = db.scalars(
        select(Promo).where(Promo.toko_id == toko.id).order_by(Promo.created_at)
    )
    return [_lengkapi(db, p) for p in rows]


@router.get("/aktif", response_model=list[PromoResponse])
def daftar_promo_aktif(
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    rows = db.scalars(
        select(Promo).where(Promo.aktif.is_(True)).order_by(Promo.created_at)
    )
    sekarang = now_utc()
    aktif = []
    for promo in rows:
        if promo.jenis == "kilat" and promo.berakhir_at is not None:
            berakhir = promo.berakhir_at
            if berakhir.tzinfo is not None:
                berakhir = berakhir.replace(tzinfo=None)
            batas = sekarang.replace(tzinfo=None)
            if berakhir <= batas:
                continue
        aktif.append(_lengkapi(db, promo))
    return aktif


@router.get("/toko/{toko_id}", response_model=list[PromoResponse])
def daftar_promo_customer(
    toko_id: UUID,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    return [_lengkapi(db, p) for p in promo_aktif(db, toko_id)]


@router.patch("/{promo_id}", response_model=PromoResponse)
def ubah_promo(
    promo_id: UUID,
    data: PromoUpdate,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    promo = db.scalar(
        select(Promo).where(Promo.id == promo_id, Promo.toko_id == toko.id)
    )
    if promo is None:
        raise HTTPException(404, "Promo tidak ditemukan")
    promo.aktif = data.aktif
    db.commit()
    db.refresh(promo)
    return _lengkapi(db, promo)


@router.delete("/{promo_id}", status_code=204)
def hapus_promo(
    promo_id: UUID,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    promo = db.scalar(
        select(Promo).where(Promo.id == promo_id, Promo.toko_id == toko.id)
    )
    if promo is None:
        raise HTTPException(404, "Promo tidak ditemukan")
    db.delete(promo)
    db.commit()
    return None

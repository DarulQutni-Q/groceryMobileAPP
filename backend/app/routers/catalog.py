from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import get_authenticated_user
from app.db.session import get_db
from app.models.produk import Produk
from app.models.toko import Toko
from app.schemas.catalog import PromoResponse, TokoDetail, TokoPublic
from app.schemas.pagination import Page
from app.services.catalog import store_detail, stores_page
from app.services.pagination import Pagination, pagination_params

router = APIRouter(tags=["Katalog"], dependencies=[Depends(get_authenticated_user)])


@router.get("/toko", response_model=Page[TokoPublic])
def toko_list(
    pagination: Pagination | None = Depends(pagination_params), db: Session = Depends(get_db)
):
    return stores_page(db, pagination or Pagination(1, 20))


@router.get("/toko/{toko_id}", response_model=TokoDetail)
def toko_detail(
    toko_id: UUID,
    pagination: Pagination | None = Depends(pagination_params),
    db: Session = Depends(get_db),
):
    return store_detail(toko_id, db, pagination or Pagination(1, 20))


@router.get("/kategori", response_model=list[str])
def kategori(db: Session = Depends(get_db)):
    return db.scalars(
        select(Produk.kategori)
        .join(Toko, Toko.id == Produk.toko_id)
        .where(Toko.status == "buka", Produk.is_tersedia.is_(True))
        .distinct()
        .order_by(Produk.kategori)
    ).all()


@router.get("/promo", response_model=list[PromoResponse])
def promo():
    # TODO: Ganti promo demo B2 dengan promo aktif dari database.
    return [
        {
            "id": "b2-voucher-demo",
            "judul": "INDOMARET POINKU • PROMO SPESIAL",
            "deskripsi": "Ada 4 voucher belanja diskon 50% siap kamu pakai.",
            "label_tombol": "Klaim Semua Voucher",
            "is_demo": True,
        }
    ]

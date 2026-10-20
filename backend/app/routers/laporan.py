from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.toko import Toko
from app.schemas.laporan import ProdukTerlaris, RingkasanLaporan
from app.services.laporan import best_products, summary
from app.services.toko import get_store

router = APIRouter(prefix="/laporan", tags=["Laporan"])


@router.get("/ringkasan", response_model=RingkasanLaporan)
def ringkasan(
    periode: Literal["7h", "30h"] = Query(default="7h", alias="range"),
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    return summary(db, toko.id, periode)


@router.get("/produk-terlaris", response_model=list[ProdukTerlaris])
def produk_terlaris(
    periode: Literal["7h", "30h"] = Query(default="7h", alias="range"),
    limit: int = Query(default=5, ge=1, le=100),
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    return best_products(db, toko.id, periode, limit)

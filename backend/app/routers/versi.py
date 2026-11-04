"""Cek versi minimum aplikasi (force-update).

Sengaja TANPA autentikasi: cek harus bisa jalan sebelum login, dan versi
aplikasi bukan informasi sensitif. Minimum diatur lewat environment
VERSI_MINIMUM_CUSTOMER / VERSI_MINIMUM_SELLER (default 0.0.0 = tidak ada
gerbang). Naikkan nilainya saat merilis versi yang wajib dipakai semua
user; aplikasi lama menampilkan layar blokir sampai diperbarui.
"""

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.versi import minimum_efektif, wajib_update

router = APIRouter(tags=["Versi"])


@router.get("/versi-minimum")
def cek_versi_minimum(
    request: Request,
    aplikasi: str = Query(pattern="^(customer|seller)$"),
    versi: str = "",
    db: Session = Depends(get_db),
):
    settings = request.app.state.settings
    minimum = minimum_efektif(
        db,
        aplikasi,
        settings.versi_minimum_customer
        if aplikasi == "customer"
        else settings.versi_minimum_seller,
    )
    return {
        "aplikasi": aplikasi,
        "versi_saat_ini": versi,
        "versi_minimum": minimum,
        "wajib_update": wajib_update(versi, minimum),
    }

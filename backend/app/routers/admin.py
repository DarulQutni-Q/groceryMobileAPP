"""Endpoint admin dashboard. Semua rute dijaga get_admin_user.

Sengaja tidak memakai ulang guard seller/customer: token admin ditolak
oleh get_authenticated_user, jadi admin punya guard sendiri yang
memeriksa role == "admin" di sisi server. Menyembunyikan menu di UI
saja tidak pernah cukup.
"""

from pathlib import Path
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.core.security import get_admin_user
from app.db.session import get_db
from app.models.pembayaran import Pembayaran
from app.models.pengaturan import Pengaturan
from app.models.pesanan import Pesanan
from app.models.produk import Produk
from app.models.toko import Toko
from app.models.user import User
from app.schemas.admin import (
    KesehatanAdmin,
    PembayaranAdmin,
    PenggunaAdmin,
    ProdukAdmin,
    RingkasanAdmin,
    VersiMinimumAdmin,
    VersiMinimumUpdate,
)
from app.schemas.pagination import Page
from app.schemas.pesanan import PesananResponse
from app.schemas.promo import PromoResponse
from app.schemas.toko import StatusUpdate, TokoResponse
from app.schemas.voucher import VoucherResponse
from app.services import admin as layanan
from app.services.pagination import Pagination, list_response, pagination_params
from app.services.versi import parse_versi

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/ringkasan", response_model=RingkasanAdmin)
def ringkasan(
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return layanan.ringkasan(db)


@router.get("/pesanan", response_model=list[PesananResponse] | Page[PesananResponse])
def daftar_pesanan(
    status: str | None = None,
    toko_id: UUID | None = None,
    q: str | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    query = layanan.daftar_pesanan(db, status, toko_id, q)
    return list_response(db, query, pagination)


@router.get("/pesanan/{pesanan_id}", response_model=PesananResponse)
def detail_pesanan(
    pesanan_id: UUID,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    pesanan = db.get(
        Pesanan, pesanan_id, options=[selectinload(Pesanan.items)]
    )
    if pesanan is None:
        raise HTTPException(404, "Pesanan tidak ditemukan")
    return pesanan


@router.get("/produk", response_model=list[ProdukAdmin] | Page[ProdukAdmin])
def daftar_produk(
    toko_id: UUID | None = None,
    kategori: str | None = None,
    q: str | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    query = layanan.daftar_produk(db, toko_id, kategori, q)
    rows = list_response(db, query, pagination)
    items = rows["data"] if isinstance(rows, dict) else rows
    detail = [layanan.produk_detail(db, produk) for produk in items]
    if isinstance(rows, dict):
        return {"data": detail, "meta": rows["meta"]}
    return detail


@router.get(
    "/pembayaran", response_model=list[PembayaranAdmin] | Page[PembayaranAdmin]
)
def daftar_pembayaran(
    status: str | None = None,
    metode: str | None = None,
    pesanan_id: UUID | None = None,
    q: str | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    query = layanan.daftar_pembayaran(db, status, metode, pesanan_id, q)
    rows = list_response(db, query, pagination)
    items = rows["data"] if isinstance(rows, dict) else rows
    detail = [layanan.pembayaran_detail(db, bayar) for bayar in items]
    if isinstance(rows, dict):
        return {"data": detail, "meta": rows["meta"]}
    return detail


@router.get("/toko", response_model=list[TokoResponse] | Page[TokoResponse])
def daftar_toko(
    status: Literal["buka", "tutup"] | None = None,
    q: str | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return list_response(db, layanan.daftar_toko(db, status, q), pagination)


@router.patch("/toko/{toko_id}/status", response_model=TokoResponse)
def ubah_status_toko(
    toko_id: UUID,
    data: StatusUpdate,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    toko = db.get(Toko, toko_id)
    if toko is None:
        raise HTTPException(404, "Toko tidak ditemukan")
    toko.status = data.status
    db.commit()
    db.refresh(toko)
    return toko


@router.get("/pengguna", response_model=list[PenggunaAdmin] | Page[PenggunaAdmin])
def daftar_pengguna(
    role: Literal["seller", "customer", "admin"] | None = None,
    q: str | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    query = layanan.daftar_pengguna(db, role, q)
    rows = list_response(db, query, pagination)
    items = rows["data"] if isinstance(rows, dict) else rows
    detail = [layanan.pengguna_detail(db, user) for user in items]
    if isinstance(rows, dict):
        return {"data": detail, "meta": rows["meta"]}
    return detail


@router.get("/pengguna/{user_id}", response_model=PenggunaAdmin)
def detail_pengguna(
    user_id: UUID,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(404, "Pengguna tidak ditemukan")
    return layanan.pengguna_detail(db, user)


@router.delete("/pengguna/{user_id}")
def hapus_pengguna(
    user_id: UUID,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(404, "Pengguna tidak ditemukan")
    if user.id == admin.id:
        raise HTTPException(403, "Admin tidak bisa menghapus akun sendiri")
    if db.scalar(select(Toko).where(Toko.owner_id == user.id)) is not None:
        raise HTTPException(
            409, "Akun ini masih memiliki toko, tutup dan pindahkan toko dulu"
        )
    if (
        db.scalar(select(Pesanan).where(Pesanan.customer_id == user.id))
        is not None
    ):
        raise HTTPException(409, "Akun ini masih memiliki riwayat pesanan")
    db.delete(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Akun masih terikat data lain")
    return {"message": "Pengguna dihapus"}


@router.get("/voucher", response_model=list[VoucherResponse] | Page[VoucherResponse])
def daftar_voucher(
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return list_response(db, layanan.daftar_voucher(db), pagination)


@router.get("/promo", response_model=list[PromoResponse] | Page[PromoResponse])
def daftar_promo(
    aktif: bool | None = None,
    pagination: Pagination | None = Depends(pagination_params),
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return list_response(db, layanan.daftar_promo(db, aktif), pagination)


@router.get("/versi-minimum", response_model=VersiMinimumAdmin)
def baca_versi_minimum(
    request: Request,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    settings = request.app.state.settings
    customer, sumber_c = layanan.versi_efektif(
        db, "customer", settings.versi_minimum_customer
    )
    seller, sumber_s = layanan.versi_efektif(
        db, "seller", settings.versi_minimum_seller
    )
    return {
        "customer": customer,
        "customer_sumber": sumber_c,
        "seller": seller,
        "seller_sumber": sumber_s,
    }


@router.patch("/versi-minimum", response_model=VersiMinimumAdmin)
def ubah_versi_minimum(
    request: Request,
    data: VersiMinimumUpdate,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    for aplikasi, nilai in (
        ("customer", data.customer),
        ("seller", data.seller),
    ):
        if nilai is None:
            continue
        if parse_versi(nilai) is None:
            raise HTTPException(400, f"Versi {aplikasi} tidak valid: {nilai}")
        row = db.get(Pengaturan, f"versi_minimum_{aplikasi}")
        if row is None:
            row = Pengaturan(kunci=f"versi_minimum_{aplikasi}", nilai=nilai)
            db.add(row)
        else:
            row.nilai = nilai
    db.commit()
    settings = request.app.state.settings
    customer, sumber_c = layanan.versi_efektif(
        db, "customer", settings.versi_minimum_customer
    )
    seller, sumber_s = layanan.versi_efektif(
        db, "seller", settings.versi_minimum_seller
    )
    return {
        "customer": customer,
        "customer_sumber": sumber_c,
        "seller": seller,
        "seller_sumber": sumber_s,
    }


@router.get("/kesehatan", response_model=KesehatanAdmin)
def kesehatan(
    request: Request,
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    settings = request.app.state.settings
    customer, _ = layanan.versi_efektif(
        db, "customer", settings.versi_minimum_customer
    )
    seller, _ = layanan.versi_efektif(
        db, "seller", settings.versi_minimum_seller
    )
    fcm_file = settings.fcm_service_account_file
    return {
        "database": "ok",
        "smtp_terkonfigurasi": bool(
            settings.smtp_host
            and settings.smtp_user
            and settings.smtp_password.get_secret_value()
        ),
        "fcm_file_ada": bool(fcm_file) and Path(fcm_file).is_file(),
        "token_fcm_total": db.scalar(
            select(func.count())
            .select_from(User)
            .where(User.fcm_token.is_not(None))
        ),
        "sweeper_terakhir_jalan": getattr(
            request.app.state, "sweeper_last_run", None
        ),
        "sweeper_jumlah_terakhir": getattr(
            request.app.state, "sweeper_last_count", None
        ),
        "versi_minimum_customer": customer,
        "versi_minimum_seller": seller,
    }

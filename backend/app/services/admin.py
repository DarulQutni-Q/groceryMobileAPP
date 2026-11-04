"""Kueri admin dashboard: ringkasan, daftar, dan kontrol versi.

Semua hitungan memakai pola yang sudah ada di codebase: agregasi SQL
untuk count/sum, perbandingan waktu Python-side dengan _tanpa_tz
(lihat sweeper) supaya sqlite-naive dan postgres-aware tidak bentrok.
"""

from datetime import datetime, time, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.pengaturan import Pengaturan
from app.models.pesanan import Pesanan
from app.models.promo import Promo
from app.models.toko import Toko
from app.models.user import User
from app.models.voucher import Voucher
from app.services.laporan import report_window

WIB = timezone(timedelta(hours=7))
BATAS_MENIT = 70


def _tanpa_tz(value):
    if value is None:
        return None
    return value.replace(tzinfo=None) if value.tzinfo is not None else value


def ringkasan(db: Session) -> dict:
    pengguna_per_role = dict(
        db.execute(
            select(User.role, func.count()).group_by(User.role)
        ).all()
    )
    pesanan_per_status = dict(
        db.execute(
            select(Pesanan.status, func.count()).group_by(Pesanan.status)
        ).all()
    )
    sekarang = datetime.now(timezone.utc)
    hari_ini = sekarang.astimezone(WIB).date()
    awal_hari = datetime.combine(hari_ini, time.min, WIB).astimezone(timezone.utc)
    akhir_hari = awal_hari + timedelta(days=1)
    pesanan_hari_ini = db.scalar(
        select(func.count())
        .select_from(Pesanan)
        .where(
            Pesanan.created_at >= awal_hari,
            Pesanan.created_at < akhir_hari,
        )
    )
    omzet = {}
    for kunci, periode in (("7h", "7h"), ("30h", "30h")):
        awal, akhir, _ = report_window(periode)
        omzet[kunci] = db.scalar(
            select(func.coalesce(func.sum(Pesanan.total), 0))
            .select_from(Pesanan)
            .where(
                Pesanan.status == "selesai",
                Pesanan.updated_at >= awal,
                Pesanan.updated_at < akhir,
            )
        )
    batas = _tanpa_tz(sekarang) - timedelta(minutes=BATAS_MENIT)
    baru = db.scalars(
        select(Pesanan.created_at).where(Pesanan.status == "baru")
    ).all()
    baru_lewat = sum(1 for c in baru if _tanpa_tz(c) < batas)
    return {
        "pengguna_total": db.scalar(select(func.count()).select_from(User)),
        "pengguna_per_role": pengguna_per_role,
        "toko_total": db.scalar(select(func.count()).select_from(Toko)),
        "toko_buka": db.scalar(
            select(func.count())
            .select_from(Toko)
            .where(Toko.status == "buka")
        ),
        "pesanan_total": db.scalar(select(func.count()).select_from(Pesanan)),
        "pesanan_per_status": pesanan_per_status,
        "pesanan_hari_ini": pesanan_hari_ini,
        "omzet_selesai_7h": omzet["7h"],
        "omzet_selesai_30h": omzet["30h"],
        "baru_lewat_70_menit": baru_lewat,
        "token_fcm_total": db.scalar(
            select(func.count())
            .select_from(User)
            .where(User.fcm_token.is_not(None))
        ),
    }


def daftar_pesanan(db: Session, status=None, toko_id=None, q=None):
    query = (
        select(Pesanan)
        .options(selectinload(Pesanan.items))
        .order_by(Pesanan.created_at.desc())
    )
    if status:
        query = query.where(Pesanan.status == status)
    if toko_id:
        query = query.where(Pesanan.toko_id == toko_id)
    if q:
        query = query.where(Pesanan.kode.ilike(f"%{q}%"))
    return query


def daftar_toko(db: Session, status=None, q=None):
    query = select(Toko).order_by(Toko.nama)
    if status:
        query = query.where(Toko.status == status)
    if q:
        query = query.where(Toko.nama.ilike(f"%{q}%"))
    return query


def daftar_pengguna(db: Session, role=None, q=None):
    query = select(User).order_by(User.created_at.desc())
    if role:
        query = query.where(User.role == role)
    if q:
        query = query.where(
            (User.nama.ilike(f"%{q}%")) | (User.email.ilike(f"%{q}%"))
        )
    return query


def pengguna_detail(db: Session, user: User) -> dict:
    toko = db.scalar(select(Toko).where(Toko.owner_id == user.id))
    pesanan_total = db.scalar(
        select(func.count())
        .select_from(Pesanan)
        .where(Pesanan.customer_id == user.id)
    )
    return {
        "id": user.id,
        "nama": user.nama,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "nama_toko": user.nama_toko,
        "toko_id": toko.id if toko else None,
        "toko_nama": toko.nama if toko else None,
        "pesanan_total": pesanan_total,
        "created_at": user.created_at,
    }


def daftar_voucher(db: Session):
    return select(Voucher).order_by(Voucher.created_at.desc())


def daftar_promo(db: Session, aktif=None):
    query = select(Promo).order_by(Promo.created_at.desc())
    if aktif is not None:
        query = query.where(Promo.aktif == aktif)
    return query


def versi_efektif(db: Session, aplikasi: str, nilai_env: str) -> tuple[str, str]:
    """Nilai minimum yang berlaku + sumbernya ('db' atau 'env')."""
    try:
        row = db.get(Pengaturan, f"versi_minimum_{aplikasi}")
    except Exception:
        return nilai_env, "env"
    if row is None or not row.nilai:
        return nilai_env, "env"
    return row.nilai, "db"

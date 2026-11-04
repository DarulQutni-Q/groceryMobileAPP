"""Skema respons endpoint admin dashboard.

List memakai bentuk {data, meta} yang sama dengan helper pagination
yang sudah ada; detail memakai ulang skema respons domain.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.pesanan import PesananResponse
from app.schemas.promo import PromoResponse
from app.schemas.toko import TokoResponse
from app.schemas.voucher import VoucherResponse


class RingkasanAdmin(BaseModel):
    pengguna_total: int
    pengguna_per_role: dict[str, int]
    toko_total: int
    toko_buka: int
    pesanan_total: int
    pesanan_per_status: dict[str, int]
    pesanan_hari_ini: int
    omzet_selesai_7h: int
    omzet_selesai_30h: int
    baru_lewat_70_menit: int
    token_fcm_total: int


class PenggunaAdmin(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    nama: str
    email: str
    phone: str | None
    role: str
    nama_toko: str | None
    toko_id: UUID | None = None
    toko_nama: str | None = None
    pesanan_total: int = 0
    created_at: datetime


class VersiMinimumAdmin(BaseModel):
    customer: str
    customer_sumber: str
    seller: str
    seller_sumber: str


class VersiMinimumUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    customer: str | None = Field(default=None, max_length=20)
    seller: str | None = Field(default=None, max_length=20)


class KesehatanAdmin(BaseModel):
    database: str
    smtp_terkonfigurasi: bool
    fcm_file_ada: bool
    token_fcm_total: int
    sweeper_terakhir_jalan: datetime | None
    sweeper_jumlah_terakhir: int | None
    versi_minimum_customer: str
    versi_minimum_seller: str


__all__ = [
    "KesehatanAdmin",
    "PenggunaAdmin",
    "PesananResponse",
    "PromoResponse",
    "RingkasanAdmin",
    "TokoResponse",
    "VersiMinimumAdmin",
    "VersiMinimumUpdate",
    "VoucherResponse",
]

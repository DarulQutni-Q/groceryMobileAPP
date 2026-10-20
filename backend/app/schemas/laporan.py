from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class PenjualanHarian(BaseModel):
    tanggal: date
    total: int


class RingkasanLaporan(BaseModel):
    total_penjualan: int = 0
    jumlah_pesanan: int = 0
    jumlah_produk_terjual: int = 0
    perbandingan_minggu_lalu: float = 0.0
    ada_pembanding: bool = False
    penjualan_per_hari: list[PenjualanHarian] = Field(default_factory=list)


class ProdukTerlaris(BaseModel):
    produk_id: UUID | None
    nama: str
    foto_url: str | None
    total_qty: int
    total_rupiah: int

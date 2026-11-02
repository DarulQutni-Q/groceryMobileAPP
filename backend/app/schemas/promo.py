from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.input import InputModel


class PromoCreate(InputModel):
    judul: str = Field(min_length=1, max_length=120)
    jenis: str = Field(default="tebus", pattern=r"^(tebus|kilat)$")
    produk_id: UUID | None = None
    harga_promo: int = Field(ge=0, le=2147483647)
    min_belanja: int = Field(default=0, ge=0, le=2147483647)
    berakhir_at: datetime | None = None


class PromoUpdate(InputModel):
    aktif: bool


class ProdukRingkas(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    toko_id: UUID
    nama: str
    harga: int
    foto_url: str | None
    satuan: str
    kategori: str
    stok: int
    is_tersedia: bool


class PromoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    toko_id: UUID
    toko_nama: str | None = None
    produk_id: UUID | None
    judul: str
    jenis: str
    harga_promo: int
    min_belanja: int
    aktif: bool
    berakhir_at: datetime | None
    created_at: datetime
    produk: ProdukRingkas | None = None

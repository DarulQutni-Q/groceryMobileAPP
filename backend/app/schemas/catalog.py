from datetime import time
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.pagination import PageMeta
from app.schemas.produk import ProdukResponse


class TokoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    nama: str
    logo_url: str | None
    alamat: str
    telepon: str
    deskripsi: str | None
    kategori: list[str]
    radius_km: int
    status: str
    metode_kirim: list[str]
    jam_buka: time | None = None
    jam_tutup: time | None = None


class TokoDetail(TokoPublic):
    produk: list[ProdukResponse]
    meta: PageMeta


class PromoResponse(BaseModel):
    id: str
    judul: str
    deskripsi: str
    label_tombol: str
    is_demo: bool

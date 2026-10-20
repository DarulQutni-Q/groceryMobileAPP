from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import ConfigDict, Field, StrictBool, field_validator, model_validator

from app.schemas.input import InputModel

Harga = Annotated[int, Field(strict=True, gt=0, le=2147483647)]
Stok = Annotated[int, Field(strict=True, ge=0, le=2147483647)]
Satuan = Literal["kg", "pcs", "liter"]


class ProdukCreate(InputModel):
    model_config = ConfigDict(extra="forbid")

    nama: str = Field(min_length=1, max_length=160)
    harga: Harga
    stok: Stok
    satuan: Satuan
    kategori: str = Field(min_length=1, max_length=80)

    @field_validator("nama", "kategori")
    @classmethod
    def required_text(cls, value):
        if not value.strip():
            raise ValueError("Nama dan kategori wajib diisi")
        return value.strip()


class ProdukUpdate(InputModel):
    model_config = ConfigDict(extra="forbid")

    nama: str | None = Field(default=None, min_length=1, max_length=160)
    harga: Harga | None = None
    stok: Stok | None = None
    satuan: Satuan | None = None
    kategori: str | None = Field(default=None, min_length=1, max_length=80)
    is_tersedia: StrictBool | None = None

    @model_validator(mode="after")
    def non_null_fields(self):
        for field in self.model_fields_set:
            value = getattr(self, field)
            if value is None or (isinstance(value, str) and not value.strip()):
                raise ValueError("Field produk tidak boleh kosong")
            if isinstance(value, str):
                setattr(self, field, value.strip())
        return self


class ProdukResponse(ProdukCreate):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    toko_id: UUID
    foto_url: str | None
    is_tersedia: bool
    created_at: datetime
    updated_at: datetime

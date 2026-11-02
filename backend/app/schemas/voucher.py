from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.input import InputModel


class VoucherCreate(InputModel):
    kode: str = Field(min_length=1, max_length=40)
    judul: str = Field(min_length=1, max_length=120)
    jenis: str = Field(default="persen", pattern=r"^(persen|gratis_ongkir)$")
    persen: int = Field(default=0, ge=0, le=100)
    cap: int = Field(default=0, ge=0, le=2147483647)
    min_belanja: int = Field(default=0, ge=0, le=2147483647)
    max_ongkir: int = Field(default=0, ge=0, le=2147483647)

    @field_validator("kode", mode="before")
    @classmethod
    def kode_upper(cls, value):
        return value.strip().upper() if isinstance(value, str) else value


class VoucherUpdate(InputModel):
    aktif: bool


class VoucherResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    toko_id: UUID
    kode: str
    judul: str
    jenis: str
    persen: int
    cap: int
    min_belanja: int
    max_ongkir: int
    aktif: bool
    created_at: datetime

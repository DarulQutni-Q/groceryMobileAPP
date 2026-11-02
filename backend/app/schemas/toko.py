from datetime import datetime, time
from typing import Literal
from uuid import UUID

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    RootModel,
    StrictBool,
    field_validator,
    model_validator,
)

from app.models.jam_buka import HARI
from app.schemas.input import PHONE_PATTERN, InputModel

KATEGORI = ("Sembako", "Sayur", "Daging dan Ikan", "Buah")
PENGIRIMAN = ("Instant", "Kurir Marketplace", "Ambil di Toko")


class TokoUpdate(InputModel):
    model_config = ConfigDict(extra="forbid")

    nama: str = Field(default="", min_length=1, max_length=120)
    alamat: str = Field(default="", max_length=2000)
    telepon: str = Field(default="", max_length=32, pattern=f"^(?:|{PHONE_PATTERN})$")
    deskripsi: str | None = Field(default=None, max_length=3000)
    kategori: list[str] = Field(default_factory=list, max_length=4)
    radius_km: int = Field(default=5, strict=True, ge=1, le=10)
    metode_kirim: list[str] = Field(default_factory=list, max_length=3)
    rekening_bank: str | None = Field(default=None, max_length=200)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)

    @field_validator("nama")
    @classmethod
    def name_required(cls, value):
        if not value.strip():
            raise ValueError("Nama wajib diisi")
        return value.strip()

    @field_validator("kategori", "metode_kirim")
    @classmethod
    def valid_choices(cls, value, info):
        allowed = KATEGORI if info.field_name == "kategori" else PENGIRIMAN
        if any(item not in allowed for item in value) or len(value) != len(set(value)):
            raise ValueError("Pilihan kategori atau pengiriman tidak valid")
        return value


class StatusUpdate(InputModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["buka", "tutup"]


class JamBukaDay(InputModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    hari: Literal["senin", "selasa", "rabu", "kamis", "jumat", "sabtu", "minggu"]
    jam_buka: time | None = None
    jam_tutup: time | None = None
    is_tutup: StrictBool = False

    @model_validator(mode="after")
    def valid_hours(self):
        if self.is_tutup:
            self.jam_buka = self.jam_tutup = None
        elif self.jam_buka is None or self.jam_tutup is None:
            raise ValueError("Jam buka dan jam tutup wajib diisi")
        elif self.jam_buka.tzinfo is not None or self.jam_tutup.tzinfo is not None:
            raise ValueError("Jam buka memakai waktu lokal tanpa offset zona waktu")
        elif self.jam_buka >= self.jam_tutup:
            raise ValueError("Jam tutup harus setelah jam buka")
        return self


class JamBukaUpdate(RootModel[list[JamBukaDay]]):
    @model_validator(mode="after")
    def seven_days(self):
        if len(self.root) != 7 or {day.hari for day in self.root} != set(HARI):
            raise ValueError("Jam buka harus berisi tujuh hari yang berbeda")
        return self


class TokoResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    owner_id: UUID
    nama: str
    logo_url: str | None
    alamat: str
    telepon: str
    deskripsi: str | None
    kategori: list[str]
    radius_km: int
    status: str
    metode_kirim: list[str]
    rekening_bank: str | None
    latitude: float | None
    longitude: float | None
    created_at: datetime
    updated_at: datetime

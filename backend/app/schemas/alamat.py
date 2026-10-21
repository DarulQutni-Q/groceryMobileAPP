from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.schemas.input import PHONE_PATTERN, InputModel


class AlamatInput(InputModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    label: str = Field(min_length=1, max_length=40)
    nama_penerima: str = Field(min_length=1, max_length=120)
    no_hp: str = Field(min_length=7, max_length=32, pattern=f"^{PHONE_PATTERN}$")
    alamat_lengkap: str = Field(min_length=1, max_length=2000)
    patokan: str | None = Field(default=None, max_length=500)
    latitude: float | None = Field(default=None, ge=-90, le=90, allow_inf_nan=False)
    longitude: float | None = Field(default=None, ge=-180, le=180, allow_inf_nan=False)
    is_utama: bool = Field(default=False, strict=True)

    @model_validator(mode="after")
    def paired_coordinates(self):
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Latitude dan longitude harus diisi bersama")
        return self


class AlamatResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    label: str
    nama_penerima: str
    no_hp: str
    alamat_lengkap: str
    patokan: str | None
    latitude: float | None
    longitude: float | None
    is_utama: bool
    created_at: datetime

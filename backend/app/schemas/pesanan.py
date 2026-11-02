from datetime import datetime, timezone
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_serializer, field_validator

from app.models.user import now_utc
from app.schemas.input import InputModel

Status = Literal["baru", "diproses", "dikemas", "diantar", "selesai", "dibatalkan", "ditolak"]
Biaya = Annotated[int, Field(strict=True, ge=0, le=2147483647)]


class ItemTest(InputModel):
    model_config = ConfigDict(extra="forbid")
    produk_id: UUID
    qty: int = Field(strict=True, gt=0, le=10000)


class PesananTest(InputModel):
    model_config = ConfigDict(extra="forbid")
    items: list[ItemTest] | None = Field(default=None, min_length=1, max_length=100)
    alamat_kirim: str = Field(default="Alamat pengujian dev", min_length=1, max_length=2000)
    catatan: str | None = Field(default=None, max_length=3000)
    metode_kirim: str = Field(default="Instant", min_length=1, max_length=80)
    slot_waktu: str = Field(default="Hari ini 15.00-17.00", min_length=1, max_length=120)
    diskon: Biaya = 0
    ongkir: Biaya = 0
    biaya_layanan: Biaya = 0

    @field_validator("alamat_kirim", "metode_kirim", "slot_waktu")
    @classmethod
    def required_text(cls, value):
        if not value.strip():
            raise ValueError("Alamat, metode kirim dan slot waktu wajib diisi")
        return value.strip()


class TolakRequest(InputModel):
    model_config = ConfigDict(extra="forbid")
    alasan: str = Field(min_length=1, max_length=1000)

    @field_validator("alasan")
    @classmethod
    def required_reason(cls, value):
        if not value.strip():
            raise ValueError("Alasan penolakan wajib diisi")
        return value.strip()


class StatusRequest(InputModel):
    model_config = ConfigDict(extra="forbid")
    status: Status


class PesananItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    pesanan_id: UUID
    produk_id: UUID | None
    nama_snapshot: str
    harga_snapshot: int
    qty: int


class PesananResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    kode: str
    customer_id: UUID | None
    toko_id: UUID
    status: str
    alamat_kirim: str
    catatan: str | None
    metode_kirim: str
    slot_waktu: str
    subtotal: int
    diskon: int
    ongkir: int
    biaya_layanan: int
    total: int
    tolak_alasan: str | None
    voucher_kode: str | None
    nama_pembeli: str | None
    telepon_pembeli: str | None
    accepted_at: datetime | None
    undo_until: datetime | None
    server_time: datetime = Field(default_factory=now_utc)
    created_at: datetime
    updated_at: datetime
    items: list[PesananItemResponse]

    @field_serializer("created_at", "updated_at", "accepted_at", "undo_until", "server_time")
    def utc_date(self, value):
        if value is None:
            return None
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat()

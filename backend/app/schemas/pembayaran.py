from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.schemas.input import InputModel
from app.schemas.pesanan import ItemTest, PesananResponse

MetodeBayar = Literal["qris", "gopay", "shopeepay", "va_bca", "va_bri", "va_mandiri", "cod"]


class CheckoutInput(InputModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    alamat_id: UUID
    metode_kirim: Literal["Instant", "Kurir Marketplace", "Ambil di Toko"]
    metode_bayar: MetodeBayar
    catatan: str | None = Field(default=None, max_length=3000)
    items: list[ItemTest] = Field(min_length=1, max_length=100)
    total_dikonfirmasi: int | None = Field(default=None, strict=True, gt=0, le=2147483647)

    @model_validator(mode="after")
    def unique_items(self):
        if len({item.produk_id for item in self.items}) != len(self.items):
            raise ValueError("Produk tidak boleh berulang")
        return self


class PembayaranResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    pesanan_id: UUID
    metode: str
    status: str
    jumlah: int
    payment_url: str | None
    paid_at: datetime | None
    perlu_rekonsiliasi: bool


class CheckoutResponse(BaseModel):
    pesanan: PesananResponse
    pembayaran: PembayaranResponse
    payment_url: str | None


class InvoiceEvent(InputModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(min_length=1, max_length=120)
    external_id: str = Field(min_length=1, max_length=80)
    status: Literal["PENDING", "PAID", "SETTLED", "EXPIRED", "FAILED"]
    amount: int = Field(strict=True, gt=0, le=2147483647)
    currency: Literal["IDR"] = "IDR"
    paid_amount: int | None = Field(default=None, strict=True, ge=0, le=2147483647)
    paid_at: datetime | None = None

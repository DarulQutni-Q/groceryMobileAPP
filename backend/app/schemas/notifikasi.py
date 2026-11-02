from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class NotifikasiResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    judul: str
    isi: str
    pesanan_id: UUID | None
    dibaca: bool
    created_at: datetime


class NotifikasiListResponse(BaseModel):
    data: list[NotifikasiResponse]
    belum_dibaca: int

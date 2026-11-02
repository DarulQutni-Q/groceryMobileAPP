from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.input import InputModel


class ChatPesanCreate(InputModel):
    isi: str = Field(min_length=1, max_length=2000)


class ChatPesanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    pesanan_id: UUID
    pengirim_id: UUID
    pengirim_peran: str
    isi: str
    created_at: datetime

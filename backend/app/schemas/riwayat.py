from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RiwayatStatusResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    pesanan_id: UUID
    status: str
    keterangan: str | None
    created_at: datetime

import uuid
from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    String,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class ChatPesan(Base):
    """Pesan chat per pesanan antara pelanggan dan toko.

    Teks saja: foto dari chat lokal lama tidak bisa dibaca pihak lain
    (path file perangkat pengirim), jadi tidak dipindahkan ke backend."""

    __tablename__ = "chat_pesan"
    __table_args__ = (
        CheckConstraint(
            "pengirim_peran IN ('customer','toko')", name="chat_peran"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    pesanan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pesanan.id"), index=True
    )
    pengirim_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    pengirim_peran: Mapped[str] = mapped_column(String(12))
    isi: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Text, Uuid
from sqlalchemy import String as SaString
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Notifikasi(Base):
    """Satu baris notifikasi untuk satu pengguna. Sumber kebenaran halaman
    Notifikasi dan badge bel; push FCM hanya salinan best-effort-nya."""

    __tablename__ = "notifikasi"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    pesanan_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("pesanan.id", ondelete="SET NULL")
    )
    judul: Mapped[str] = mapped_column(SaString(160))
    isi: Mapped[str] = mapped_column(Text)
    dibaca: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

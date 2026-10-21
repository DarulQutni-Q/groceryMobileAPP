import uuid
from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Pembayaran(Base):
    __tablename__ = "pembayaran"
    __table_args__ = (
        CheckConstraint("jumlah > 0", name="pembayaran_jumlah"),
        CheckConstraint(
            "status IN ('pending','paid','expired','failed')", name="pembayaran_status"
        ),
    )
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    pesanan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("pesanan.id"), unique=True)
    xendit_id: Mapped[str | None] = mapped_column(String(120), unique=True)
    external_id: Mapped[str] = mapped_column(String(80), unique=True)
    metode: Mapped[str] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(12), default="pending")
    jumlah: Mapped[int] = mapped_column(Integer)
    payment_url: Mapped[str | None] = mapped_column(String(2048))
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    stok_direservasi: Mapped[bool] = mapped_column(Boolean, default=True)
    perlu_rekonsiliasi: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

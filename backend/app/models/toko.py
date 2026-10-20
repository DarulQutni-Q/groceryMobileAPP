import uuid
from datetime import datetime

from sqlalchemy import JSON, CheckConstraint, DateTime, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Toko(Base):
    __tablename__ = "toko"
    __table_args__ = (
        CheckConstraint("radius_km BETWEEN 1 AND 10", name="toko_radius"),
        CheckConstraint("status IN ('buka', 'tutup')", name="toko_status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True)
    nama: Mapped[str] = mapped_column(String(120))
    logo_url: Mapped[str | None] = mapped_column(String(512))
    alamat: Mapped[str] = mapped_column(Text, default="")
    telepon: Mapped[str] = mapped_column(String(32), default="")
    deskripsi: Mapped[str | None] = mapped_column(Text)
    kategori: Mapped[list[str]] = mapped_column(JSON, default=list)
    radius_km: Mapped[int] = mapped_column(Integer, default=5)
    status: Mapped[str] = mapped_column(String(10), default="tutup")
    metode_kirim: Mapped[list[str]] = mapped_column(JSON, default=list)
    rekening_bank: Mapped[str | None] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

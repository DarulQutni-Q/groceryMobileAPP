import uuid
from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Produk(Base):
    __tablename__ = "produk"
    __table_args__ = (
        CheckConstraint("harga > 0", name="produk_harga"),
        CheckConstraint("stok >= 0", name="produk_stok"),
        CheckConstraint("satuan IN ('kg', 'pcs', 'liter')", name="produk_satuan"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    toko_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("toko.id"), index=True)
    nama: Mapped[str] = mapped_column(String(160))
    foto_url: Mapped[str | None] = mapped_column(String(512))
    harga: Mapped[int] = mapped_column(Integer)
    stok: Mapped[int] = mapped_column(Integer)
    satuan: Mapped[str] = mapped_column(String(10))
    kategori: Mapped[str] = mapped_column(String(80), index=True)
    is_tersedia: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

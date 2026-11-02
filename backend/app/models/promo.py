import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Promo(Base):
    """Harga promo milik satu toko untuk satu produk.

    Tebus: harga murah yang berlaku bila subtotal keranjang mencapai
    min_belanja. Kilat: harga murah yang sama, ditambah batas waktu
    (berakhir_at); lewat batas itu promo tidak berlaku dan tidak tampil.
    Potongan dihitung di quote() dari selisih harga asli dan harga promo,
    jadi harga coret di aplikasi tidak pernah dikarang: yang tampil hanya
    promo yang benar-benar memotong tagihan."""

    __tablename__ = "promo"
    __table_args__ = (
        CheckConstraint("jenis IN ('tebus','kilat')", name="promo_jenis"),
        CheckConstraint("harga_promo >= 0 AND min_belanja >= 0", name="promo_nilai"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    toko_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("toko.id"), index=True)
    produk_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("produk.id"))
    judul: Mapped[str] = mapped_column(String(120))
    jenis: Mapped[str] = mapped_column(String(12), default="tebus")
    harga_promo: Mapped[int] = mapped_column(Integer)
    min_belanja: Mapped[int] = mapped_column(Integer, default=0)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
    berakhir_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

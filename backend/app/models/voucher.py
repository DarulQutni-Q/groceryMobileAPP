import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    CheckConstraint,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import now_utc


class Voucher(Base):
    """Voucher milik satu toko. Jenis persen memotong tagihan (dibatasi cap,
    mensyaratkan minimal belanja); jenis gratis_ongkir menanggung ongkir
    sampai max_ongkir (ongkir hari ini 0, jadi potongannya 0 sampai ongkir
    benar-benar diberlakukan)."""

    __tablename__ = "voucher"
    __table_args__ = (
        CheckConstraint("jenis IN ('persen','gratis_ongkir')", name="voucher_jenis"),
        CheckConstraint("persen >= 0 AND persen <= 100", name="voucher_persen"),
        CheckConstraint(
            "cap >= 0 AND min_belanja >= 0 AND max_ongkir >= 0", name="voucher_nilai"
        ),
        UniqueConstraint("toko_id", "kode", name="voucher_kode_per_toko"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    toko_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("toko.id"), index=True)
    kode: Mapped[str] = mapped_column(String(40))
    judul: Mapped[str] = mapped_column(String(120))
    jenis: Mapped[str] = mapped_column(String(12), default="persen")
    persen: Mapped[int] = mapped_column(Integer, default=0)
    cap: Mapped[int] = mapped_column(Integer, default=0)
    min_belanja: Mapped[int] = mapped_column(Integer, default=0)
    max_ongkir: Mapped[int] = mapped_column(Integer, default=0)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

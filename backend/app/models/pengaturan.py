"""Pengaturan aplikasi key-value (diatur admin dashboard).

Dipakai untuk nilai yang dulu hanya dari environment, supaya admin bisa
mengubahnya tanpa recreate container: kunci 'versi_minimum_customer'
dan 'versi_minimum_seller' meng-override VERSI_MINIMUM_* dari env.
Baris yang tidak ada berarti pakai nilai env.
"""

from datetime import datetime, timezone

from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def now_utc():
    return datetime.now(timezone.utc)


class Pengaturan(Base):
    __tablename__ = "pengaturan"

    kunci: Mapped[str] = mapped_column(String(64), primary_key=True)
    nilai: Mapped[str] = mapped_column(String(255))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

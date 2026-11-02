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


class RiwayatStatus(Base):
    """Jejak perubahan status satu pesanan, ditulis di transaksi yang sama
    dengan perubahan statusnya (lihat transition() dan finalize_order).
    Pesanan lama (sebelum fitur ini) tidak punya baris: UI tidak boleh
    mengarang riwayat untuk mereka."""

    __tablename__ = "riwayat_status"
    __table_args__ = (
        CheckConstraint(
            "status IN ('baru','diproses','dikemas','diantar','selesai','dibatalkan','ditolak')",
            name="riwayat_status_nilai",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    pesanan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pesanan.id"), index=True
    )
    status: Mapped[str] = mapped_column(String(20))
    keterangan: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

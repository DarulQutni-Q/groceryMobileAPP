import uuid
from datetime import time

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, String, Time, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

HARI = ("senin", "selasa", "rabu", "kamis", "jumat", "sabtu", "minggu")


class JamBuka(Base):
    __tablename__ = "jam_buka"
    __table_args__ = (
        UniqueConstraint("toko_id", "hari", name="jam_toko_hari"),
        CheckConstraint(
            "is_tutup OR (jam_buka IS NOT NULL AND jam_tutup IS NOT NULL AND jam_buka < jam_tutup)",
            name="jam_urutan",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    toko_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("toko.id", ondelete="CASCADE"))
    hari: Mapped[str] = mapped_column(String(10))
    jam_buka: Mapped[time | None] = mapped_column(Time)
    jam_tutup: Mapped[time | None] = mapped_column(Time)
    is_tutup: Mapped[bool] = mapped_column(Boolean, default=False)

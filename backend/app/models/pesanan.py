import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.user import User, now_utc

STATUS = ("baru", "diproses", "dikemas", "diantar", "selesai", "dibatalkan", "ditolak")
TAB_STATUS = {
    "baru": ("baru",),
    "diproses": ("diproses", "dikemas", "diantar"),
    "selesai": ("selesai", "dibatalkan", "ditolak"),
}


class Pesanan(Base):
    __tablename__ = "pesanan"
    __table_args__ = (
        CheckConstraint(f"status IN {STATUS}", name="pesanan_status"),
        CheckConstraint(
            "subtotal >= 0 AND diskon >= 0 AND ongkir >= 0 AND biaya_layanan >= 0",
            name="pesanan_biaya",
        ),
        CheckConstraint(
            "total = subtotal - diskon + ongkir + biaya_layanan AND total >= 0",
            name="pesanan_total",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    kode: Mapped[str] = mapped_column(String(8), unique=True)
    customer_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"))
    toko_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("toko.id"), index=True)
    status: Mapped[str] = mapped_column(String(12), default="baru")
    alamat_kirim: Mapped[str] = mapped_column(Text)
    catatan: Mapped[str | None] = mapped_column(Text)
    metode_kirim: Mapped[str] = mapped_column(String(80))
    slot_waktu: Mapped[str] = mapped_column(String(120))
    subtotal: Mapped[int] = mapped_column(Integer)
    diskon: Mapped[int] = mapped_column(Integer, default=0)
    ongkir: Mapped[int] = mapped_column(Integer, default=0)
    biaya_layanan: Mapped[int] = mapped_column(Integer, default=0)
    total: Mapped[int] = mapped_column(Integer)
    tolak_alasan: Mapped[str | None] = mapped_column(Text)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )
    items: Mapped[list["PesananItem"]] = relationship(
        cascade="all, delete-orphan", order_by="PesananItem.id"
    )
    customer: Mapped[User | None] = relationship(foreign_keys=[customer_id])

    @property
    def nama_pembeli(self):
        return self.customer.nama if self.customer else None

    @property
    def telepon_pembeli(self):
        return self.customer.phone if self.customer else None

    @property
    def undo_until(self):
        if self.status != "diproses" or self.accepted_at is None:
            return None
        accepted = self.accepted_at
        if accepted.tzinfo is None:
            accepted = accepted.replace(tzinfo=timezone.utc)
        return accepted.astimezone(timezone.utc) + timedelta(seconds=10)


class PesananItem(Base):
    __tablename__ = "pesanan_item"
    __table_args__ = (
        CheckConstraint("qty > 0 AND harga_snapshot > 0", name="pesanan_item_jumlah"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    pesanan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("pesanan.id", ondelete="CASCADE"), index=True
    )
    produk_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("produk.id", ondelete="SET NULL")
    )
    nama_snapshot: Mapped[str] = mapped_column(String(160))
    harga_snapshot: Mapped[int] = mapped_column(Integer)
    qty: Mapped[int] = mapped_column(Integer)

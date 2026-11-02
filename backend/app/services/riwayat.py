"""Penulis jejak status. Dipanggil di transaksi yang sama dengan
perubahan status, jadi riwayat tidak pernah mendahului status."""

from sqlalchemy.orm import Session

from app.models.riwayat import RiwayatStatus


def catat_riwayat(db: Session, pesanan, status: str, keterangan=None):
    db.add(
        RiwayatStatus(
            pesanan_id=pesanan.id, status=status, keterangan=keterangan
        )
    )
    db.flush()

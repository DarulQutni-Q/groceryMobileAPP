"""Penulis baris notifikasi tersimpan.

Setiap perubahan status pesanan menulis satu baris untuk customer, dan
setiap pesanan baru menulis satu baris untuk pemilik toko. Baris ditulis
di transaksi yang sama dengan perubahan pesanannya (flush saja, commit
oleh pemanggil), jadi tidak ada status berubah tanpa jejak notifikasinya.
Pengiriman push FCM tetap best-effort terpisah di services/fcm.py.
"""

from sqlalchemy.orm import Session

from app.models.notifikasi import Notifikasi
from app.models.pesanan import Pesanan
from app.models.toko import Toko
from app.services.fcm import STATUS_LABELS


def tulis_notifikasi(db: Session, user_id, judul, isi, pesanan_id=None):
    row = Notifikasi(user_id=user_id, judul=judul, isi=isi, pesanan_id=pesanan_id)
    db.add(row)
    db.flush()
    return row


def catat_status_pesanan(db: Session, pesanan: Pesanan):
    """Satu baris untuk customer atas status baru pesanan. None bila
    pesanan tidak punya customer (pesanan uji)."""
    if pesanan.customer_id is None:
        return None
    label = STATUS_LABELS.get(pesanan.status, pesanan.status)
    return tulis_notifikasi(
        db,
        pesanan.customer_id,
        f"Pesanan {pesanan.kode}",
        f"Status pesananmu kini: {label}",
        pesanan.id,
    )


def catat_pembatalan_untuk_toko(db: Session, pesanan: Pesanan, toko: Toko):
    """Satu baris untuk pemilik toko atas pesanan yang dibatalkan pelanggan."""
    return tulis_notifikasi(
        db,
        toko.owner_id,
        f"Pesanan {pesanan.kode} dibatalkan",
        "Pelanggan membatalkan pesanan ini.",
        pesanan.id,
    )


def catat_pesanan_baru(db: Session, pesanan: Pesanan, toko: Toko):
    """Satu baris untuk pemilik toko atas pesanan baru."""
    total = f"Rp {pesanan.total:,}".replace(",", ".")
    return tulis_notifikasi(
        db,
        toko.owner_id,
        f"Pesanan baru {pesanan.kode}",
        f"Pesanan baru senilai {total} dari pelanggan.",
        pesanan.id,
    )

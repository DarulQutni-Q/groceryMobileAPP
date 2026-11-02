"""Sweeper pesanan tak dibayar.

Invoice Xendit berlaku 60 menit (invoice_duration 3600). Sweeper berjalan
setiap 5 menit dan membatalkan pesanan yang pembayarannya masih pending
lebih dari 70 menit: 10 menit setelah invoice Xendit kedaluwarsa, supaya
pembayaran di menit-menit akhir masih sempat masuk.

Aman terhadap reconcile: sebelum membatalkan, tiap kandidat direkonsiliasi
dulu ke Xendit (kalau callback rekonsiliasi diberikan). Kalau ternyata
sudah paid, kandidat dilewati — sweeper tidak pernah membatalkan pesanan
yang sebenarnya sudah dibayar. Tanpa callback (mis. di tes), kandidat
langsung dibatalkan.

Pembatalan memakai transition() yang sama dengan tombol batalkan, jadi
stok dikembalikan, notifikasi + riwayat status tercatat, dan pembayaran
pending ditandai failed — semuanya dalam satu transaksi per pesanan.
"""

from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan
from app.services.pesanan import transition

BATAS_MENIT = 70


def _tanpa_tz(waktu):
    return waktu.replace(tzinfo=None) if waktu.tzinfo else waktu


def kadaluarsa_pesanan_tak_dibayar(db, batas_menit=BATAS_MENIT, sekarang=None, rekonsiliasi=None):
    """Batalkan pesanan 'baru' yang pembayarannya pending melewati batas.

    Mengembalikan jumlah pesanan yang dibatalkan.
    """
    sekarang = _tanpa_tz(sekarang or datetime.now(timezone.utc))
    batas = sekarang - timedelta(minutes=batas_menit)
    kandidat = db.scalars(
        select(Pembayaran)
        .join(Pesanan, Pembayaran.pesanan_id == Pesanan.id)
        .where(
            Pembayaran.status == "pending",
            Pembayaran.metode != "cod",
            Pesanan.status == "baru",
        )
    ).all()
    dibatalkan = 0
    for payment in kandidat:
        if _tanpa_tz(payment.created_at) >= batas:
            continue
        if rekonsiliasi is not None:
            payment = rekonsiliasi(db, payment)
            if payment.status != "pending":
                continue
        pesanan = db.get(Pesanan, payment.pesanan_id)
        if pesanan is None or pesanan.status != "baru":
            continue
        transition(db, pesanan, "dibatalkan", reason="Batas waktu pembayaran habis")
        dibatalkan += 1
    return dibatalkan

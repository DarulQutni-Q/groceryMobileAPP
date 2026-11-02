"""Aturan hitung voucher. Satu-satunya tempat potongan voucher dihitung,
dipakai quote() checkout supaya preview dan penagihan selalu sama."""

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.voucher import Voucher


def cari_voucher_aktif(db: Session, toko_id, kode: str):
    return db.scalar(
        select(Voucher).where(
            Voucher.toko_id == toko_id,
            Voucher.kode == kode.strip().upper(),
            Voucher.aktif.is_(True),
        )
    )


def potongan_voucher(voucher: Voucher, subtotal: int, ongkir: int):
    """Kembalikan (potongan_tagihan, potongan_ongkir). Satu-satunya jenis
    adalah persen; potongan ongkir selalu 0."""
    if voucher.jenis == "persen":
        hitung = subtotal * voucher.persen // 100
        return (hitung if hitung < voucher.cap else voucher.cap), 0
    return 0, 0


def terapkan_voucher(db: Session, toko_id, kode: str, subtotal: int, ongkir: int):
    """Validasi voucher dan hitung potongannya. 400 bila kode tidak ada,
    tidak aktif, atau minimal belanja belum terpenuhi."""
    voucher = cari_voucher_aktif(db, toko_id, kode)
    if voucher is None:
        raise HTTPException(400, "Voucher tidak ditemukan atau tidak aktif")
    if subtotal < voucher.min_belanja:
        raise HTTPException(400, "Subtotal belum memenuhi minimal belanja voucher")
    diskon, potongan_ongkir = potongan_voucher(voucher, subtotal, ongkir)
    return voucher, diskon, potongan_ongkir

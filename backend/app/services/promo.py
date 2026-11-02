"""Aturan potongan promo. Dipakai quote() supaya preview dan penagihan
selalu memakai harga promo yang sama."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.promo import Promo
from app.models.user import now_utc


def _masih_berlaku(promo, sekarang):
    if promo.jenis != "kilat" or promo.berakhir_at is None:
        return True
    berakhir = promo.berakhir_at
    if berakhir.tzinfo is not None:
        berakhir = berakhir.replace(tzinfo=None)
    if sekarang.tzinfo is not None:
        sekarang = sekarang.replace(tzinfo=None)
    return berakhir > sekarang


def promo_aktif(db: Session, toko_id, sekarang=None):
    """Promo aktif satu toko; kilat yang sudah lewat tidak ikut."""
    sekarang = sekarang or now_utc()
    rows = db.scalars(
        select(Promo).where(Promo.toko_id == toko_id, Promo.aktif.is_(True))
    )
    return [p for p in rows if _masih_berlaku(p, sekarang)]


def potongan_promo(db: Session, toko_id, items, subtotal: int):
    """Potongan total dari promo: untuk tiap item, harga promo terendah
    yang berlaku (tebus mensyaratkan subtotal >= min_belanja, kilat juga
    mensyaratkan belum berakhir). Kembalikan (potongan, daftar promo
    yang terpakai)."""
    promos = promo_aktif(db, toko_id)
    if not promos:
        return 0, []
    harga = {i["produk_id"]: i["harga_snapshot"] for i in items}
    qty = {i["produk_id"]: i["qty"] for i in items}
    total = 0
    terpakai = []
    for promo in promos:
        if promo.produk_id is None or promo.produk_id not in harga:
            continue
        if subtotal < promo.min_belanja:
            continue
        selisih = harga[promo.produk_id] - promo.harga_promo
        if selisih <= 0:
            continue
        # Bila dua promo menyasar produk yang sama, yang terendah menang:
        # hitung per produk sekali dengan harga promo terendah.
        terpakai.append((promo, selisih))
    terbaik = {}
    for promo, selisih in terpakai:
        if promo.produk_id not in terbaik or selisih > terbaik[promo.produk_id][1]:
            terbaik[promo.produk_id] = (promo, selisih)
    for promo, selisih in terbaik.values():
        total += selisih * qty[promo.produk_id]
    return total, [p for p, _ in terbaik.values()]

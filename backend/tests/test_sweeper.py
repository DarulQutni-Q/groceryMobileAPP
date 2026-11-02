"""Sweeper pesanan tak dibayar: batalkan yang pending melewati batas,
lewati yang masih segar, yang COD, dan yang ternyata sudah paid saat
direkonsiliasi. Stok dikembalikan lewat transition() yang sama."""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models.notifikasi import Notifikasi
from app.models.pembayaran import Pembayaran
from app.models.pesanan import Pesanan, PesananItem
from app.models.produk import Produk
from app.models.riwayat import RiwayatStatus
from app.models.toko import Toko
from app.models.user import User
from app.services.sweeper import kadaluarsa_pesanan_tak_dibayar

# Impor model lain supaya Base.metadata lengkap (relasi antar tabel).
import app.models.alamat  # noqa: F401
import app.models.chat  # noqa: F401
import app.models.promo  # noqa: F401
import app.models.voucher  # noqa: F401


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    session = sessionmaker(engine, expire_on_commit=False)()
    yield session
    session.close()
    engine.dispose()


def _dunia(db, menit_lalu, metode="qris"):
    owner = User(nama="Owner", email="owner@x.test", role="seller")
    customer = User(nama="Cust", email="cust@x.test", role="customer")
    db.add_all([owner, customer])
    db.flush()
    toko = Toko(owner_id=owner.id, nama="Toko Uji", status="buka")
    db.add(toko)
    db.flush()
    produk = Produk(
        toko_id=toko.id, nama="Beras", harga=5000, stok=8,
        satuan="kg", kategori="Sembako",
    )
    db.add(produk)
    db.flush()
    pesanan = Pesanan(
        kode="SW-" + uuid.uuid4().hex[:5].upper(),
        customer_id=customer.id, toko_id=toko.id, status="baru", alamat_kirim="Jalan Melati 1", metode_kirim="antar", slot_waktu="pagi",
        subtotal=10000, diskon=0, ongkir=0, biaya_layanan=0, total=10000,
    )
    db.add(pesanan)
    db.flush()
    db.add(PesananItem(pesanan_id=pesanan.id, produk_id=produk.id, nama_snapshot="Beras", qty=2, harga_snapshot=5000))
    payment = Pembayaran(
        pesanan_id=pesanan.id, external_id="EXT-" + uuid.uuid4().hex[:8],
        metode=metode, status="pending", jumlah=10000,
        created_at=datetime.now(timezone.utc) - timedelta(minutes=menit_lalu),
        stok_direservasi=True,
    )
    db.add(payment)
    db.commit()
    return pesanan, produk, payment


def test_kadaluarsa_dibatalkan_dan_stok_kembali(db):
    pesanan, produk, payment = _dunia(db, 80)
    assert kadaluarsa_pesanan_tak_dibayar(db) == 1
    db.refresh(pesanan)
    db.refresh(produk)
    db.refresh(payment)
    assert pesanan.status == "dibatalkan"
    assert payment.status == "failed"
    assert produk.stok == 10
    assert db.query(RiwayatStatus).filter_by(pesanan_id=pesanan.id).count() == 1
    assert db.query(Notifikasi).filter_by(pesanan_id=pesanan.id).count() >= 1


def test_masih_segar_tidak_disentuh(db):
    pesanan, _, _ = _dunia(db, 30)
    assert kadaluarsa_pesanan_tak_dibayar(db) == 0
    db.refresh(pesanan)
    assert pesanan.status == "baru"


def test_cod_tidak_disentuh(db):
    pesanan, _, _ = _dunia(db, 200, metode="cod")
    assert kadaluarsa_pesanan_tak_dibayar(db) == 0
    db.refresh(pesanan)
    assert pesanan.status == "baru"


def test_sudah_paid_saat_rekonsiliasi_tidak_dibatalkan(db):
    pesanan, _, payment = _dunia(db, 80)

    def rekonsiliasi(db_, payment_):
        payment_.status = "paid"
        db_.flush()
        return payment_

    assert kadaluarsa_pesanan_tak_dibayar(db, rekonsiliasi=rekonsiliasi) == 0
    db.refresh(pesanan)
    assert pesanan.status == "baru"

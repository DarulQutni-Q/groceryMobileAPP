from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.chat import ChatPesan
from app.models.pesanan import Pesanan
from app.models.toko import Toko
from app.models.user import User
from app.schemas.chat import ChatPesanCreate, ChatPesanResponse
from app.services.alamat import get_customer
from app.services.notifikasi import tulis_notifikasi
from app.services.toko import get_store

router = APIRouter(prefix="/chat", tags=["Chat"])


def _pesanan_customer(db: Session, pesanan_id: UUID, user: User):
    pesanan = db.scalar(
        select(Pesanan).where(
            Pesanan.id == pesanan_id, Pesanan.customer_id == user.id
        )
    )
    if pesanan is None:
        raise HTTPException(404, "Pesanan tidak ditemukan")
    return pesanan


def _pesanan_toko(db: Session, pesanan_id: UUID, toko: Toko):
    pesanan = db.scalar(
        select(Pesanan).where(
            Pesanan.id == pesanan_id, Pesanan.toko_id == toko.id
        )
    )
    if pesanan is None:
        raise HTTPException(404, "Pesanan tidak ditemukan")
    return pesanan


@router.get("/pesanan/{pesanan_id}", response_model=list[ChatPesanResponse])
def daftar_chat(
    pesanan_id: UUID,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    pesanan = _pesanan_customer(db, pesanan_id, user)
    return db.scalars(
        select(ChatPesan)
        .where(ChatPesan.pesanan_id == pesanan.id)
        .order_by(ChatPesan.created_at)
    ).all()


@router.post("/pesanan/{pesanan_id}", response_model=ChatPesanResponse, status_code=201)
def kirim_chat(
    pesanan_id: UUID,
    data: ChatPesanCreate,
    user: User = Depends(get_customer),
    db: Session = Depends(get_db),
):
    pesanan = _pesanan_customer(db, pesanan_id, user)
    pesan = ChatPesan(
        pesanan_id=pesanan.id,
        pengirim_id=user.id,
        pengirim_peran="customer",
        isi=data.isi.strip(),
    )
    db.add(pesan)
    db.flush()
    if pesanan.toko_id is not None:
        toko = db.scalar(select(Toko).where(Toko.id == pesanan.toko_id))
        if toko is not None:
            tulis_notifikasi(
                db,
                toko.owner_id,
                f"Pesan baru {pesanan.kode}",
                "Pelanggan mengirim pesan tentang pesanan ini.",
                pesanan.id,
            )
    db.commit()
    db.refresh(pesan)
    return pesan


@router.get("/toko/pesanan/{pesanan_id}", response_model=list[ChatPesanResponse])
def daftar_chat_toko(
    pesanan_id: UUID,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    pesanan = _pesanan_toko(db, pesanan_id, toko)
    return db.scalars(
        select(ChatPesan)
        .where(ChatPesan.pesanan_id == pesanan.id)
        .order_by(ChatPesan.created_at)
    ).all()


@router.post("/toko/pesanan/{pesanan_id}", response_model=ChatPesanResponse, status_code=201)
def kirim_chat_toko(
    pesanan_id: UUID,
    data: ChatPesanCreate,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    pesanan = _pesanan_toko(db, pesanan_id, toko)
    pesan = ChatPesan(
        pesanan_id=pesanan.id,
        pengirim_id=toko.owner_id,
        pengirim_peran="toko",
        isi=data.isi.strip(),
    )
    db.add(pesan)
    db.flush()
    if pesanan.customer_id is not None:
        tulis_notifikasi(
            db,
            pesanan.customer_id,
            f"Pesan baru dari toko ({pesanan.kode})",
            "Toko mengirim pesan tentang pesananmu.",
            pesanan.id,
        )
    db.commit()
    db.refresh(pesan)
    return pesan

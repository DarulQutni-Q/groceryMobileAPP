from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile
from sqlalchemy import func, select, update
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.produk import Produk
from app.models.toko import Toko
from app.schemas.produk import ProdukCreate, ProdukResponse, ProdukUpdate
from app.services.foto import read_photo, remove_photo, save_photo
from app.services.toko import get_store

router = APIRouter(prefix="/produk", tags=["Produk"])


def get_produk(
    produk_id: UUID, toko: Toko = Depends(get_store), db: Session = Depends(get_db)
) -> Produk:
    produk = db.scalar(
        select(Produk)
        .where(Produk.id == produk_id, Produk.toko_id == toko.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if produk is None:
        raise HTTPException(404, "Produk tidak ditemukan")
    return produk


@router.get("", response_model=list[ProdukResponse])
def listing(
    q: str = Query(default="", max_length=160),
    kategori: str = Query(default="", max_length=80),
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    query = select(Produk).where(Produk.toko_id == toko.id)
    if q.strip():
        query = query.where(func.lower(Produk.nama).contains(q.strip().lower(), autoescape=True))
    if kategori:
        query = query.where(Produk.kategori == kategori)
    return db.scalars(query.order_by(Produk.created_at.desc(), Produk.id)).all()


@router.post("", response_model=ProdukResponse)
def create(data: ProdukCreate, toko: Toko = Depends(get_store), db: Session = Depends(get_db)):
    produk = Produk(toko_id=toko.id, **data.model_dump())
    db.add(produk)
    db.commit()
    return produk


@router.get("/{produk_id}", response_model=ProdukResponse)
def detail(produk: Produk = Depends(get_produk)):
    return produk


@router.put("/{produk_id}", response_model=ProdukResponse)
def edit(data: ProdukUpdate, produk: Produk = Depends(get_produk), db: Session = Depends(get_db)):
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(produk, field, value)
    db.commit()
    return produk


@router.delete("/{produk_id}")
def delete(request: Request, produk: Produk = Depends(get_produk), db: Session = Depends(get_db)):
    old_url = produk.foto_url
    db.delete(produk)
    db.commit()
    remove_photo(request.app.state.settings.uploads_dir, old_url)
    return {"message": "Produk dihapus"}


@router.patch("/{produk_id}/toggle", response_model=ProdukResponse)
def toggle(produk: Produk = Depends(get_produk), db: Session = Depends(get_db)):
    changed = db.scalar(
        update(Produk)
        .where(Produk.id == produk.id)
        .values(is_tersedia=~Produk.is_tersedia)
        .returning(Produk)
        .execution_options(populate_existing=True)
    )
    if changed is None:
        raise HTTPException(404, "Produk tidak ditemukan")
    db.commit()
    return changed


@router.post("/{produk_id}/foto", response_model=ProdukResponse)
def upload(
    request: Request,
    file: UploadFile,
    produk: Produk = Depends(get_produk),
    db: Session = Depends(get_db),
):
    data, ext = read_photo(file)
    produk = db.scalar(
        select(Produk)
        .where(Produk.id == produk.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if produk is None:
        raise HTTPException(404, "Produk tidak ditemukan")
    directory = request.app.state.settings.uploads_dir
    new_url = save_photo(directory, data, ext)
    old_url = produk.foto_url
    produk.foto_url = new_url
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        remove_photo(directory, new_url)
        raise HTTPException(503, "Foto belum dapat disimpan. Coba lagi.") from exc
    remove_photo(directory, old_url)
    return produk

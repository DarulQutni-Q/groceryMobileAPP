from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.jam_buka import HARI, JamBuka
from app.models.toko import Toko
from app.models.user import User
from app.schemas.toko import JamBukaDay, JamBukaUpdate, StatusUpdate, TokoResponse, TokoUpdate
from app.services.foto import read_photo, remove_photo, save_photo
from app.services.toko import get_store

router = APIRouter(prefix="/toko", tags=["Toko"])


@router.get("/me", response_model=TokoResponse)
def profil(toko: Toko = Depends(get_store)):
    return toko


@router.put("/me", response_model=TokoResponse)
def update_profil(data: TokoUpdate, toko: Toko = Depends(get_store), db: Session = Depends(get_db)):
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(toko, field, value)
    db.get(User, toko.owner_id).nama_toko = toko.nama
    db.commit()
    return toko


@router.patch("/me/status", response_model=TokoResponse)
def update_status(
    data: StatusUpdate, toko: Toko = Depends(get_store), db: Session = Depends(get_db)
):
    toko.status = data.status
    db.commit()
    return toko


@router.get("/me/jam-buka", response_model=list[JamBukaDay])
def jam_buka(toko: Toko = Depends(get_store), db: Session = Depends(get_db)):
    days = db.scalars(select(JamBuka).where(JamBuka.toko_id == toko.id)).all()
    return sorted(days, key=lambda day: HARI.index(day.hari))


@router.put("/me/jam-buka", response_model=list[JamBukaDay])
def update_jam(data: JamBukaUpdate, toko: Toko = Depends(get_store), db: Session = Depends(get_db)):
    db.scalar(select(Toko).where(Toko.id == toko.id).with_for_update())
    days = {day.hari: day for day in jam_buka(toko, db)}
    for value in data.root:
        for field, item in value.model_dump().items():
            setattr(days[value.hari], field, item)
    db.commit()
    return jam_buka(toko, db)


@router.post("/me/logo", response_model=TokoResponse)
def upload_logo(
    request: Request,
    file: UploadFile,
    toko: Toko = Depends(get_store),
    db: Session = Depends(get_db),
):
    data, ext = read_photo(file)
    toko = db.scalar(
        select(Toko)
        .where(Toko.id == toko.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if toko is None:
        raise HTTPException(404, "Toko tidak ditemukan")
    directory = request.app.state.settings.uploads_dir
    new_url = save_photo(directory, data, ext)
    old_url = toko.logo_url
    toko.logo_url = new_url
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        remove_photo(directory, new_url)
        raise HTTPException(503, "Logo belum dapat disimpan. Coba lagi.") from exc
    remove_photo(directory, old_url)
    return toko

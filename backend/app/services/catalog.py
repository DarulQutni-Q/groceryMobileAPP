from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import and_, func, select

from app.models.jam_buka import HARI, JamBuka
from app.models.produk import Produk
from app.models.toko import Toko
from app.schemas.catalog import TokoPublic
from app.services.pagination import list_response


def visible_products():
    return (
        select(Produk)
        .join(Toko, Toko.id == Produk.toko_id)
        .where(Toko.status == "buka", Produk.is_tersedia.is_(True))
    )


def store_query():
    today = HARI[datetime.now(timezone(timedelta(hours=7))).weekday()]
    return (
        select(Toko, JamBuka.jam_buka, JamBuka.jam_tutup, JamBuka.is_tutup)
        .outerjoin(JamBuka, and_(JamBuka.toko_id == Toko.id, JamBuka.hari == today))
        .where(Toko.status == "buka")
    )


def public_store(row):
    return TokoPublic.model_validate(row[0]).model_copy(
        update={
            "jam_buka": row[1] if not row[3] else None,
            "jam_tutup": row[2] if not row[3] else None,
        }
    )


def stores_page(db, pagination):
    query = store_query().order_by(Toko.nama, Toko.id)
    total = db.scalar(select(func.count()).select_from(query.order_by(None).subquery()))
    rows = db.execute(
        query.offset((pagination.page - 1) * pagination.per_page).limit(pagination.per_page)
    )
    return {
        "data": [public_store(row) for row in rows],
        "meta": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": total,
            "total_pages": (total + pagination.per_page - 1) // pagination.per_page,
        },
    }


def store_detail(toko_id, db, pagination):
    row = db.execute(store_query().where(Toko.id == toko_id)).first()
    if row is None:
        raise HTTPException(404, "Toko tidak ditemukan atau sedang tutup")
    products = list_response(
        db,
        visible_products()
        .where(Produk.toko_id == toko_id)
        .order_by(Produk.created_at.desc(), Produk.id),
        pagination,
    )
    return {**public_store(row).model_dump(), "produk": products["data"], "meta": products["meta"]}

from dataclasses import dataclass

from fastapi import Query, Request
from sqlalchemy import func, select


@dataclass(frozen=True)
class Pagination:
    page: int
    per_page: int


def pagination_params(
    request: Request,
    page: int = Query(default=1, ge=1, le=2147483647),
    per_page: int = Query(default=20, ge=1),
) -> Pagination | None:
    if "page" not in request.query_params and "per_page" not in request.query_params:
        return None
    return Pagination(page, min(per_page, 100))


def list_response(db, query, pagination: Pagination | None):
    if pagination is None:
        return db.scalars(query).unique().all()
    total = db.scalar(select(func.count()).select_from(query.order_by(None).subquery()))
    rows = (
        db.scalars(
            query.offset((pagination.page - 1) * pagination.per_page).limit(pagination.per_page)
        )
        .unique()
        .all()
    )
    return {
        "data": rows,
        "meta": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": total,
            "total_pages": (total + pagination.per_page - 1) // pagination.per_page,
        },
    }

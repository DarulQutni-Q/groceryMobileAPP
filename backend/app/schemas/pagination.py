from pydantic import BaseModel


class PageMeta(BaseModel):
    page: int
    per_page: int
    total: int
    total_pages: int


class Page[T](BaseModel):
    data: list[T]
    meta: PageMeta

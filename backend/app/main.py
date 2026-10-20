import json
import logging
import secrets
from contextlib import asynccontextmanager
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse, JSONResponse
from limits.storage import storage_from_string
from limits.strategies import FixedWindowRateLimiter
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings
from app.core.cors import ConfiguredCors
from app.core.security import hash_password
from app.core.upload_limit import UploadLimit
from app.db.base import Base
from app.db.session import get_db
from app.routers.auth import router
from app.routers.laporan import router as laporan_router
from app.routers.pesanan import router as pesanan_router
from app.routers.produk import router as produk_router
from app.routers.toko import router as toko_router
from app.services.foto import FILE_PATTERN, FORMATS


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = Settings()
    engine = create_engine(settings.database_url, pool_pre_ping=True, hide_parameters=True)
    app.state.settings = settings
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    app.state.engine = engine
    app.state.sessions = sessionmaker(engine, expire_on_commit=False)
    app.state.dummy_hash = hash_password(secrets.token_urlsafe(24))
    app.state.login_limiter = FixedWindowRateLimiter(
        storage_from_string(settings.rate_limit_storage_uri)
    )
    if settings.auto_create_tables:
        Base.metadata.create_all(engine)
    try:
        yield
    finally:
        engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(title="Daclanari Grocery", lifespan=lifespan)
    app.include_router(router)
    app.include_router(toko_router)
    app.include_router(produk_router)
    app.include_router(pesanan_router)
    app.include_router(laporan_router)
    app.add_exception_handler(RequestValidationError, validation_error)
    app.add_middleware(ConfiguredCors)
    app.add_middleware(UploadLimit)
    app.middleware("http")(request_context)
    app.add_api_route("/health", health, methods=["GET"])
    app.add_api_route("/uploads/{filename}", photo_file, methods=["GET"], include_in_schema=False)
    return app


async def validation_error(request: Request, exc: RequestValidationError):
    messages = []
    for error in exc.errors():
        field = str(error["loc"][-1])
        message = str(error["msg"]).removeprefix("Value error, ")
        if field == "email":
            message = "Alamat email tidak valid"
        elif field in {"harga", "stok", "satuan"}:
            message = {
                "harga": "Harga harus lebih dari 0 dan berupa bilangan bulat",
                "stok": "Stok harus 0 atau lebih dan berupa bilangan bulat",
                "satuan": "Satuan harus kg, pcs, atau liter",
            }[field]
        elif error["type"] == "missing":
            message = f"Kolom {field} wajib diisi"
        elif error["type"] != "value_error":
            message = f"Isian {field} tidak valid"
        messages.append({"field": field, "message": message})
    return JSONResponse(status_code=422, content={"detail": messages})


async def request_context(request: Request, call_next):
    request_id = str(uuid4())
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    logging.getLogger("grocery.requests").info(
        json.dumps(
            {
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status": response.status_code,
            }
        )
    )
    return response


def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        raise HTTPException(503, "Database belum dapat dihubungi") from exc
    return {"status": "ok", "database": "ok"}


def photo_file(filename: str, request: Request):
    if not FILE_PATTERN.fullmatch(filename):
        raise HTTPException(404, "Foto tidak ditemukan")
    path = request.app.state.settings.uploads_dir / filename
    if not path.is_file():
        raise HTTPException(404, "Foto tidak ditemukan")
    mime = next(mime for ext, mime in FORMATS.values() if filename.endswith(f".{ext}"))
    return FileResponse(path, media_type=mime, headers={"X-Content-Type-Options": "nosniff"})


app = create_app()

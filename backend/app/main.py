import secrets
from contextlib import asynccontextmanager

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
from app.core.request_log import RequestLog
from app.core.security import hash_password
from app.core.upload_limit import UploadLimit
from app.core.validation import check_json_depth, validation_error
from app.db.base import Base
from app.db.session import get_db
from app.routers.alamat import router as alamat_router
from app.routers.auth import router
from app.routers.catalog import router as catalog_router
from app.routers.laporan import router as laporan_router
from app.routers.pembayaran import router as pembayaran_router
from app.routers.notifikasi import router as notifikasi_router
from app.routers.voucher import router as voucher_router
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
        storage_from_string(settings.rate_limit_storage_uri, wrap_exceptions=True)
    )
    if settings.auto_create_tables:
        Base.metadata.create_all(engine)
    try:
        yield
    finally:
        engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title="Daclanari Grocery",
        version="1.0.0",
        lifespan=lifespan,
        dependencies=[Depends(check_json_depth)],
    )
    app.include_router(router)
    app.include_router(alamat_router)
    app.include_router(pembayaran_router)
    app.include_router(toko_router)
    app.include_router(produk_router)
    app.include_router(catalog_router)
    app.include_router(pesanan_router)
    app.include_router(notifikasi_router)
    app.include_router(voucher_router)
    app.include_router(laporan_router)
    app.add_exception_handler(RequestValidationError, validation_error)
    app.add_middleware(ConfiguredCors)
    app.add_middleware(UploadLimit)
    app.add_middleware(RequestLog)
    @app.get("/")
    def root():
        return {
            "app": "Daclanari Grocery API",
            "status": "online",
            "health": "/health",
            "version": "1.0.0",
        }

    app.add_api_route("/health", health, methods=["GET"])
    app.add_api_route("/uploads/{filename}", photo_file, methods=["GET"], include_in_schema=False)
    return app


def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        return JSONResponse(
            status_code=503,
            content={"status": "error", "database": "error", "version": "1.0.0"},
        )
    return {"status": "ok", "database": "ok", "version": "1.0.0"}


def photo_file(filename: str, request: Request):
    if not FILE_PATTERN.fullmatch(filename):
        raise HTTPException(404, "Foto tidak ditemukan")
    path = request.app.state.settings.uploads_dir / filename
    if not path.is_file():
        raise HTTPException(404, "Foto tidak ditemukan")
    mime = next(mime for ext, mime in FORMATS.values() if filename.endswith(f".{ext}"))
    return FileResponse(path, media_type=mime, headers={"X-Content-Type-Options": "nosniff"})


app = create_app()

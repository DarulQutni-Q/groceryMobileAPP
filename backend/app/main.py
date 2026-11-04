import asyncio
import logging
import os
import secrets
from datetime import datetime, timezone
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse, JSONResponse
from limits.storage import storage_from_string
from limits.strategies import FixedWindowRateLimiter
from sqlalchemy import create_engine, select, text
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
from app.routers.promo import router as promo_router
from app.routers.chat import router as chat_router
from app.routers.pesanan import router as pesanan_router
from app.routers.versi import router as versi_router
from app.routers.admin import router as admin_router
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from app.services.pembayaran import reconcile_with_xendit
from app.services.sweeper import kadaluarsa_pesanan_tak_dibayar
from app.services.xendit import Xendit
from app.routers.produk import router as produk_router
from app.routers.toko import router as toko_router
from app.services.foto import FILE_PATTERN, FORMATS


async def _sweeper_loop(app: FastAPI):
    """Tiap 5 menit: batalkan pesanan tak dibayar yang melewati batas.

    Loop tidak pernah mematikan server: galat apa pun dicatat lalu loop
    tidur lagi. Rekonsiliasi Xendit jalan dulu per kandidat, jadi pesanan
    yang ternyata sudah paid tidak ikut dibatalkan.
    """
    log = logging.getLogger("grocery.sweeper")
    while True:
        await asyncio.sleep(300)
        try:
            gateway = lambda metode: Xendit(app.state.settings, metode)
            with app.state.sessions() as db:
                jumlah = kadaluarsa_pesanan_tak_dibayar(
                    db,
                    rekonsiliasi=lambda db_, payment: reconcile_with_xendit(
                        db_, payment, gateway
                    ),
                )
            app.state.sweeper_last_run = datetime.now(timezone.utc)
            app.state.sweeper_last_count = jumlah
            if jumlah:
                log.info("sweeper membatalkan %d pesanan tak dibayar", jumlah)
        except asyncio.CancelledError:
            raise
        except Exception:
            log.exception("sweeper gagal, dicoba lagi 5 menit berikutnya")


def _seed_admin(app: FastAPI):
    """Buat akun admin dari ADMIN_EMAIL/ADMIN_PASSWORD bila diset dan
    belum ada. Kegagalan seed tidak menggagalkan startup: dicatat saja,
    dan dicoba lagi saat start berikutnya."""
    settings = app.state.settings
    email = (settings.admin_email or "").strip().lower()
    password = settings.admin_password.get_secret_value()
    if not email or not password:
        return
    try:
        from app.models.user import User

        with app.state.sessions() as db:
            if db.scalar(select(User).where(User.email == email)) is not None:
                return
            db.add(
                User(
                    nama="Admin",
                    email=email,
                    password_hash=hash_password(password),
                    role="admin",
                )
            )
            db.commit()
        logging.getLogger("grocery.admin").info("akun admin dibuat")
    except Exception:
        logging.getLogger("grocery.admin").exception("seed admin gagal")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = Settings()
    engine = create_engine(settings.database_url, pool_pre_ping=True, hide_parameters=True)
    app.state.settings = settings
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    app.state.engine = engine
    app.state.sessions = sessionmaker(engine, expire_on_commit=False)
    app.state.dummy_hash = hash_password(secrets.token_urlsafe(24))
    app.state.sweeper_last_run = None
    app.state.sweeper_last_count = None
    app.state.login_limiter = FixedWindowRateLimiter(
        storage_from_string(settings.rate_limit_storage_uri, wrap_exceptions=True)
    )
    if settings.auto_create_tables:
        Base.metadata.create_all(engine)
    # Seed setelah tabel dijamin ada (create_all/migrasi), bukan sebelumnya.
    _seed_admin(app)
    tugas_sweeper = asyncio.create_task(_sweeper_loop(app))
    try:
        yield
    finally:
        tugas_sweeper.cancel()
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
    app.include_router(promo_router)
    app.include_router(chat_router)
    app.include_router(laporan_router)
    app.include_router(versi_router)
    app.include_router(admin_router)
    admin_dir = Path(os.environ.get("ADMIN_WEB_DIR", "/srv/admin"))
    if (admin_dir / "index.html").is_file():
        app.mount("/dashboard", StaticFiles(directory=admin_dir, html=True), name="dashboard")
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

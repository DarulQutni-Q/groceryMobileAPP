import logging
import random
from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.models.password_reset_otp import PasswordResetOtp
from app.models.user import User
from app.schemas.auth import RegisterRequest, TokenResponse
from app.services.toko import create_store


def token_response(user: User, secret: str) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user.id, secret),
        refresh_token=create_refresh_token(user.id, secret),
    )


def register_user(data: RegisterRequest, db: Session) -> User:
    email = str(data.email).lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(400, "Email sudah terdaftar")
    user = User(
        nama=data.nama_pemilik or email.split("@")[0][:120],
        nama_toko=data.nama_toko if data.role == "seller" else None,
        email=email,
        phone=data.phone,
        password_hash=hash_password(data.password),
        role=data.role,
    )
    db.add(user)
    try:
        if data.role == "seller":
            create_store(user, db)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        duplicate_email = db.scalar(select(User).where(User.email == email))
        message = "Email sudah terdaftar" if duplicate_email else "Nomor telepon sudah terdaftar"
        raise HTTPException(400, message) from exc
    db.refresh(user)
    return user


def password_user(query, password: str, db: Session, dummy_hash: str, message: str) -> User:
    user = db.scalar(query)
    stored_hash = user.password_hash if user and user.password_hash else dummy_hash
    valid = verify_password(password, stored_hash)
    if not user or not valid or not user.password_hash:
        raise HTTPException(401, message)
    return user


def login_user(email: str, password: str, db: Session, dummy_hash: str, role="seller") -> User:
    query = select(User).where(User.email == email.lower(), User.role == role)
    return password_user(query, password, db, dummy_hash, "Email atau kata sandi salah")


def login_customer_phone(phone: str, password: str, db: Session, dummy_hash: str) -> User:
    query = select(User).where(User.phone == phone, User.role == "customer")
    return password_user(query, password, db, dummy_hash, "Nomor handphone atau kata sandi salah")


def google_user(claims: dict, db: Session, role: str = "seller") -> User:
    subject = claims.get("sub")
    email = claims.get("email", "").lower()
    if not subject or not email or claims.get("email_verified") is not True:
        raise HTTPException(401, "Akun Google belum terverifikasi")
    user = db.scalar(
        select(User).options(joinedload(User.toko)).where(User.google_subject == subject)
    )
    if user:
        if user.role != role:
            if role == "seller":
                user.role = "seller"
                if not user.toko:
                    create_store(user, db)
                db.commit()
                db.refresh(user)
                return user
            raise HTTPException(401, "Gunakan aplikasi yang sesuai dengan peran akun")
        if role == "seller" and not user.toko:
            create_store(user, db)
            db.commit()
            db.refresh(user)
        return user
    existing = db.scalar(
        select(User).options(joinedload(User.toko)).where(User.email == email)
    )
    if existing:
        if existing.role != role:
            if role == "seller":
                existing.role = "seller"
                existing.google_subject = subject
                if not existing.toko:
                    create_store(existing, db)
                db.commit()
                db.refresh(existing)
                return existing
            raise HTTPException(401, "Gunakan aplikasi yang sesuai dengan peran akun")
        existing.google_subject = subject
        if role == "seller" and not existing.toko:
            create_store(existing, db)
        db.commit()
        db.refresh(existing)
        return existing
    user = User(
        nama=claims.get("name") or email.split("@")[0],
        email=email,
        auth_provider="google",
        google_subject=subject,
        role=role,
    )
    db.add(user)
    try:
        if role == "seller":
            create_store(user, db)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(400, "Akun sudah terdaftar. Silakan login kembali.") from exc
    db.refresh(user)
    return user

_log = logging.getLogger(__name__)


def _mask_phone(phone: str | None) -> str | None:
    if not phone:
        return None
    digits = phone.lstrip("+")
    if len(digits) < 8:
        return phone
    return phone[:4] + " **** " + phone[-4:]


def request_otp(email: str, db: Session) -> tuple[str, int, str | None]:
    email = email.lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        raise HTTPException(404, "Alamat email belum terdaftar")
    code = f"{random.randint(0, 999999):06d}"
    _log.info("OTP untuk %s: %s", email, code)
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=300)
    otp = PasswordResetOtp(email=email, code=code, expires_at=expires_at)
    db.add(otp)
    db.commit()
    return code, 300, _mask_phone(user.phone)


def verify_otp(email: str, code: str, db: Session, secret: str) -> str:
    email = email.lower()
    now = datetime.now(timezone.utc)
    otp = db.scalar(
        select(PasswordResetOtp)
        .where(
            PasswordResetOtp.email == email,
            PasswordResetOtp.code == code,
            PasswordResetOtp.used.is_(False),
            PasswordResetOtp.expires_at > now,
        )
        .order_by(PasswordResetOtp.created_at.desc())
        .limit(1)
    )
    if otp is None:
        raise HTTPException(400, "Kode verifikasi tidak valid atau telah kedaluwarsa")
    from app.core.security import create_token

    reset_token = create_token(UUID(int=0), secret, "reset_password", timedelta(minutes=15))
    # Encode email in token via sub claim workaround: store email in a separate JWT claim.
    # We use jose directly to include email in the token payload.
    from datetime import datetime as _dt
    from uuid import uuid4

    from jose import jwt

    now_ts = _dt.now(timezone.utc)
    claims = {
        "sub": email,
        "type": "reset_password",
        "iat": now_ts,
        "exp": now_ts + timedelta(minutes=15),
        "iss": "grocery-api",
        "aud": "grocery-seller",
        "jti": str(uuid4()),
    }
    reset_token = jwt.encode(claims, secret, algorithm="HS256")
    return reset_token


def reset_password(
    email: str, reset_token: str, new_password: str, db: Session, secret: str
) -> None:
    from jose import JWTError, jwt

    try:
        payload = jwt.decode(
            reset_token,
            secret,
            algorithms=["HS256"],
            audience="grocery-seller",
            issuer="grocery-api",
            options={"require_exp": True, "require_iat": True, "require_sub": True},
        )
        if payload.get("type") != "reset_password":
            raise ValueError("Jenis token tidak sesuai")
        token_email = payload["sub"]
    except (JWTError, ValueError, KeyError) as exc:
        raise HTTPException(400, "Token reset tidak valid atau sudah kedaluwarsa") from exc

    if token_email.lower() != email.lower():
        raise HTTPException(400, "Token reset tidak valid atau sudah kedaluwarsa")

    user = db.scalar(select(User).where(User.email == email.lower()))
    if user is None:
        raise HTTPException(404, "Alamat email belum terdaftar")

    # Invalidate OTP records for this email
    otps = db.scalars(
        select(PasswordResetOtp).where(
            PasswordResetOtp.email == email.lower(),
            PasswordResetOtp.used.is_(False),
        )
    ).all()
    for otp in otps:
        otp.used = True

    user.password_hash = hash_password(new_password)
    db.commit()

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import SellerRegisterRequest, TokenResponse


def token_response(user: User, secret: str) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user.id, secret),
        refresh_token=create_refresh_token(user.id, secret),
    )


def register_seller(data: SellerRegisterRequest, db: Session) -> User:
    email = str(data.email).lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(400, "Email sudah terdaftar")
    user = User(
        nama=data.nama_pemilik,
        nama_toko=data.nama_toko,
        email=email,
        phone=data.phone,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        duplicate_email = db.scalar(select(User).where(User.email == email))
        message = "Email sudah terdaftar" if duplicate_email else "Nomor telepon sudah terdaftar"
        raise HTTPException(400, message) from exc
    db.refresh(user)
    return user


def login_seller(email: str, password: str, db: Session, dummy_hash: str) -> User:
    user = db.scalar(select(User).where(User.email == email.lower()))
    stored_hash = user.password_hash if user and user.password_hash else dummy_hash
    valid = verify_password(password, stored_hash)
    if not user or not valid or user.role != "seller" or not user.password_hash:
        raise HTTPException(401, "Email atau kata sandi salah")
    return user


def google_seller(claims: dict, db: Session) -> User:
    subject = claims.get("sub")
    email = claims.get("email", "").lower()
    if not subject or not email or claims.get("email_verified") is not True:
        raise HTTPException(401, "Akun Google belum terverifikasi")
    user = db.scalar(select(User).where(User.google_subject == subject))
    if user:
        if user.role != "seller":
            raise HTTPException(401, "Akun seller tidak ditemukan")
        return user
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(400, "Email sudah terdaftar. Gunakan metode login semula.")
    user = User(
        nama=claims.get("name") or email.split("@")[0],
        email=email,
        auth_provider="google",
        google_subject=subject,
        role="seller",
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(400, "Akun sudah terdaftar. Silakan login kembali.") from exc
    db.refresh(user)
    return user

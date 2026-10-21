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
    user = db.scalar(select(User).where(User.google_subject == subject))
    if user:
        if user.role != role:
            raise HTTPException(401, "Gunakan aplikasi yang sesuai dengan peran akun")
        return user
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(400, "Email sudah terdaftar. Gunakan metode login semula.")
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

from fastapi import APIRouter, Depends, HTTPException, Request
from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token
from sqlalchemy.orm import Session

from app.core.rate_limit import check_login_limit
from app.core.security import decode_user_id, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    FcmTokenRequest,
    GoogleLoginRequest,
    LoginRequest,
    RefreshRequest,
    SellerRegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.services.auth import google_seller, login_seller, register_seller, token_response

router = APIRouter(prefix="/auth", tags=["Auth seller"])


@router.post("/register", response_model=TokenResponse)
def register(data: SellerRegisterRequest, request: Request, db: Session = Depends(get_db)):
    user = register_seller(data, db)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, request: Request, db: Session = Depends(get_db)):
    check_login_limit(request)
    user = login_seller(data.email, data.password, db, request.app.state.dummy_hash)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.post("/refresh", response_model=TokenResponse)
def refresh(data: RefreshRequest, request: Request, db: Session = Depends(get_db)):
    user = db.get(User, decode_user_id(data.refresh_token, request, "refresh"))
    if user is None or user.role != "seller":
        raise HTTPException(401, "Akun seller tidak ditemukan")
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.patch("/fcm-token")
def update_fcm(
    data: FcmTokenRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user.fcm_token = data.fcm_token
    db.commit()
    return {"message": "Token notifikasi tersimpan"}


@router.post("/google", response_model=TokenResponse)
def google(data: GoogleLoginRequest, request: Request, db: Session = Depends(get_db)):
    check_login_limit(request)
    audience = request.app.state.settings.google_client_id
    if not audience:
        raise HTTPException(503, "Login Google belum dikonfigurasi")
    try:
        claims = id_token.verify_oauth2_token(data.id_token, GoogleRequest(), audience)
    except ValueError as exc:
        raise HTTPException(401, "Login Google gagal. Silakan coba lagi.") from exc
    except GoogleAuthError as exc:
        raise HTTPException(503, "Google belum dapat dihubungi. Coba lagi nanti.") from exc
    user = google_seller(claims, db)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())

from fastapi import APIRouter, Depends, HTTPException, Request
from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token
from sqlalchemy.orm import Session

from app.core.rate_limit import check_login_limit, check_register_limit, check_user_limit
from app.core.security import decode_user_id, get_authenticated_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    FcmTokenRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    GoogleLoginRequest,
    LoginRequest,
    PhoneLoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    ResetPasswordResponse,
    TokenResponse,
    UserResponse,
    VerifyOtpRequest,
    VerifyOtpResponse,
)
from app.services.auth import (
    google_user,
    login_customer_phone,
    login_user,
    register_user,
    request_otp,
    reset_password,
    token_response,
    verify_otp,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    check_register_limit(request)
    user = register_user(data, db)
    request.state.user_id = str(user.id)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_authenticated_user)):
    return user


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, request: Request, db: Session = Depends(get_db)):
    check_login_limit(request)
    user = login_user(data.email, data.password, db, request.app.state.dummy_hash, data.role)
    request.state.user_id = str(user.id)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.post("/login/phone", response_model=TokenResponse)
def login_phone(data: PhoneLoginRequest, request: Request, db: Session = Depends(get_db)):
    check_login_limit(request)
    user = login_customer_phone(data.phone, data.password, db, request.app.state.dummy_hash)
    request.state.user_id = str(user.id)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.post("/refresh", response_model=TokenResponse)
def refresh(data: RefreshRequest, request: Request, db: Session = Depends(get_db)):
    user = db.get(User, decode_user_id(data.refresh_token, request, "refresh"))
    if user is None or user.role not in {"seller", "customer"}:
        raise HTTPException(401, "Akun tidak ditemukan")
    check_user_limit(request, user.id)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.patch("/fcm-token")
def update_fcm(
    data: FcmTokenRequest,
    user: User = Depends(get_authenticated_user),
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
    user = google_user(claims, db, data.role)
    request.state.user_id = str(user.id)
    return token_response(user, request.app.state.settings.jwt_secret.get_secret_value())


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
def forgot_password(
    data: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    _, expires_in, masked_phone = request_otp(
        str(data.email), db, request.app.state.settings
    )
    return ForgotPasswordResponse(
        message="Kode verifikasi telah dikirim",
        email=str(data.email),
        expires_in=expires_in,
        masked_phone=masked_phone,
    )


@router.post("/verify-otp", response_model=VerifyOtpResponse)
def verify_otp_endpoint(data: VerifyOtpRequest, request: Request, db: Session = Depends(get_db)):
    secret = request.app.state.settings.jwt_secret.get_secret_value()
    token = verify_otp(str(data.email), data.otp, db, secret)
    return VerifyOtpResponse(message="Kode verifikasi valid", reset_token=token)


@router.post("/reset-password", response_model=ResetPasswordResponse)
def reset_password_endpoint(
    data: ResetPasswordRequest, request: Request, db: Session = Depends(get_db)
):
    secret = request.app.state.settings.jwt_secret.get_secret_value()
    reset_password(str(data.email), data.reset_token, data.password, db, secret)
    return ResetPasswordResponse(message="Kata sandi berhasil diperbarui")

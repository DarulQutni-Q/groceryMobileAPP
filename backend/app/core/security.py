from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import bcrypt
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.rate_limit import check_user_limit
from app.db.session import get_db
from app.models.user import User

bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, password_hash: str | None) -> bool:
    if password_hash is None or len(password.encode()) > 72:
        return False
    return bcrypt.checkpw(password.encode(), password_hash.encode())


def create_token(user_id: UUID, secret: str, kind: str, duration: timedelta) -> str:
    now = datetime.now(timezone.utc)
    claims = {
        "sub": str(user_id),
        "type": kind,
        "iat": now,
        "exp": now + duration,
        "iss": "grocery-api",
        "aud": "grocery-seller",
        "jti": str(uuid4()),
    }
    return jwt.encode(claims, secret, algorithm="HS256")


def create_access_token(user_id: UUID, secret: str) -> str:
    return create_token(user_id, secret, "access", timedelta(minutes=15))


def create_refresh_token(user_id: UUID, secret: str) -> str:
    return create_token(user_id, secret, "refresh", timedelta(days=7))


def decode_user_id(token: str, request: Request, kind: str) -> UUID:
    try:
        payload = jwt.decode(
            token,
            request.app.state.settings.jwt_secret.get_secret_value(),
            algorithms=["HS256"],
            audience="grocery-seller",
            issuer="grocery-api",
            options={"require_exp": True, "require_iat": True, "require_sub": True},
        )
        if payload.get("type") != kind:
            raise ValueError("Jenis token tidak sesuai")
        return UUID(payload["sub"])
    except (JWTError, ValueError, KeyError) as exc:
        raise HTTPException(401, "Sesi tidak valid atau sudah berakhir") from exc


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(401, "Silakan login terlebih dahulu")
    user = db.get(User, decode_user_id(credentials.credentials, request, "access"))
    if user is None or user.role != "seller":
        raise HTTPException(401, "Akun seller tidak ditemukan")
    check_user_limit(request, user.id)
    return user

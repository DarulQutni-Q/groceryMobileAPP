import math
import time

from fastapi import HTTPException, Request
from limits import parse
from limits.errors import StorageError

LOGIN_LIMIT = parse("5/minute")
REGISTER_LIMIT = parse("3/minute")
WRITE_LIMIT = parse("60/minute")


def check_limit(request: Request, limit, namespace: str, identity: str) -> None:
    limiter = request.app.state.login_limiter
    try:
        if limiter.hit(limit, namespace, identity):
            return
        remaining = math.ceil(
            limiter.get_window_stats(limit, namespace, identity).reset_time - time.time()
        )
    except StorageError as exc:
        raise HTTPException(503, "Pembatas permintaan belum tersedia, coba lagi nanti") from exc
    seconds = max(1, remaining)
    raise HTTPException(
        429,
        f"Terlalu banyak permintaan, coba lagi dalam {seconds} detik",
        headers={"Retry-After": str(seconds)},
    )


def check_login_limit(request: Request) -> None:
    peer = request.client.host if request.client else "unknown"
    check_limit(request, LOGIN_LIMIT, "login", peer)


def check_register_limit(request: Request) -> None:
    peer = request.client.host if request.client else "unknown"
    check_limit(request, REGISTER_LIMIT, "register", peer)


def check_user_limit(request: Request, user_id) -> None:
    request.state.user_id = str(user_id)
    if request.method in {"POST", "PUT", "PATCH", "DELETE"}:
        check_limit(request, WRITE_LIMIT, "mutations", str(user_id))

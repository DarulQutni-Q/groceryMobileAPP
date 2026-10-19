from fastapi import HTTPException, Request
from limits import parse

LOGIN_LIMIT = parse("5/minute")


def check_login_limit(request: Request) -> None:
    peer = request.client.host if request.client else "unknown"
    if not request.app.state.login_limiter.hit(LOGIN_LIMIT, peer):
        raise HTTPException(
            429,
            "Terlalu banyak percobaan login. Coba lagi dalam satu menit.",
            headers={"Retry-After": "60"},
        )

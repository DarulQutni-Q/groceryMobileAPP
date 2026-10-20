import json
import logging
import sys
import time
import traceback
from datetime import datetime, timezone
from uuid import uuid4

from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

class StderrHandler(logging.StreamHandler):
    def emit(self, record):
        self.stream = sys.stderr
        super().emit(record)


logger = logging.getLogger("grocery.requests")
logger.setLevel(logging.INFO)
logger.propagate = False
if not logger.handlers:
    logger.addHandler(StderrHandler())


class RequestLog:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        started = time.perf_counter()
        request_id = str(uuid4())
        state = scope.setdefault("state", {})
        state["request_id"] = request_id
        status, sent = 500, False

        async def response_send(message):
            nonlocal status, sent
            if message["type"] == "http.response.start":
                status, sent = message["status"], True
                message["headers"] = [
                    (key, value)
                    for key, value in message.get("headers", [])
                    if key.lower() != b"x-request-id"
                ] + [(b"x-request-id", request_id.encode())]
            await send(message)

        try:
            await self.app(scope, receive, response_send)
        except Exception as exc:
            logger.error(
                json.dumps({"request_id": request_id, "traceback": traceback.format_exc()})
            )
            if not sent:
                unavailable = isinstance(exc, SQLAlchemyError)
                response = JSONResponse(
                    status_code=503 if unavailable else 500,
                    content={
                        "detail": "Layanan belum tersedia. Coba lagi."
                        if unavailable
                        else "Terjadi kesalahan server. Hubungi pengelola dengan ID permintaan."
                    },
                )
                await response(scope, receive, response_send)
            raise
        finally:
            logger.info(
                json.dumps(
                    {
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "request_id": request_id,
                        "method": scope["method"],
                        "path": scope["path"],
                        "status_code": status,
                        "duration_ms": round((time.perf_counter() - started) * 1000, 3),
                        "user_id": state.get("user_id"),
                    }
                )
            )

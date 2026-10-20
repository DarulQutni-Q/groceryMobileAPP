from starlette.exceptions import HTTPException

from app.services.foto import MAX_BYTES


class UploadLimit:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if (
            scope["type"] != "http"
            or not scope["path"].startswith("/produk/")
            or not scope["path"].endswith("/foto")
        ):
            return await self.app(scope, receive, send)
        total = 0

        async def limited_receive():
            nonlocal total
            message = await receive()
            total += len(message.get("body", b""))
            if total > MAX_BYTES + 65536:
                raise HTTPException(422, "Foto maksimal 5 MB")
            return message

        await self.app(scope, limited_receive, send)

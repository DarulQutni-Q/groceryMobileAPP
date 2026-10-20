from starlette.middleware.cors import CORSMiddleware


class ConfiguredCors:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        methods = ["GET", "POST", "PATCH"]
        if scope["path"].startswith("/produk"):
            methods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
        elif scope["path"].startswith("/toko"):
            methods = ["GET", "PUT", "PATCH"]
        middleware = CORSMiddleware(
            self.app,
            allow_origins=scope["app"].state.settings.cors_origins,
            allow_methods=methods,
            allow_headers=["Authorization", "Content-Type"],
        )
        await middleware(scope, receive, send)

from starlette.middleware.cors import CORSMiddleware


class ConfiguredCors:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        middleware = CORSMiddleware(
            self.app,
            allow_origins=scope["app"].state.settings.cors_origins,
            allow_methods=["GET", "POST", "PATCH"],
            allow_headers=["Authorization", "Content-Type"],
        )
        await middleware(scope, receive, send)

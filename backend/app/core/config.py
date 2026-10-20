from pathlib import Path
from urllib.parse import urlsplit

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", hide_input_in_errors=True)

    database_url: str
    jwt_secret: SecretStr = Field(min_length=32)
    cors_origins: list[str] = []
    google_client_id: str = ""
    auto_create_tables: bool = False
    rate_limit_storage_uri: str = "memory://"
    uploads_dir: Path = Path("uploads")
    env: str = "prod"

    @model_validator(mode="after")
    def valid_origins(self):
        for origin in self.cors_origins:
            if origin == "*" and self.env == "dev":
                continue
            url = urlsplit(origin)
            if (
                url.scheme not in {"http", "https"}
                or not url.hostname
                or "*" in origin
                or url.username
                or url.password
                or url.path
                or url.query
                or url.fragment
                or any(ord(char) <= 32 or ord(char) == 127 for char in origin)
            ):
                raise ValueError(
                    "CORS_ORIGINS harus berisi origin HTTP/HTTPS tanpa wildcard atau path"
                )
            if url.port is not None and not 1 <= url.port <= 65535:
                raise ValueError("Port CORS_ORIGINS tidak valid")
        return self

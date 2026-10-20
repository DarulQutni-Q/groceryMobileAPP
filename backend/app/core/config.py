from pathlib import Path

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str
    jwt_secret: SecretStr = Field(min_length=32)
    cors_origins: list[str] = []
    google_client_id: str = ""
    auto_create_tables: bool = False
    rate_limit_storage_uri: str = "memory://"
    uploads_dir: Path = Path("uploads")

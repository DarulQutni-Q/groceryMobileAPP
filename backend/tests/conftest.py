import os
import secrets
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.main import create_app


@pytest.fixture
def client(monkeypatch, tmp_path):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'auth.db'}")
    monkeypatch.setenv("JWT_SECRET", secrets.token_urlsafe(48))
    monkeypatch.setenv("XENDIT_API_KEY", "")
    monkeypatch.setenv("XENDIT_WEBHOOK_TOKEN", "")
    monkeypatch.setenv("GOOGLE_CLIENT_ID", "")
    monkeypatch.setenv("AUTO_CREATE_TABLES", "true")
    monkeypatch.setenv("UPLOADS_DIR", str(tmp_path / "uploads"))
    monkeypatch.setenv("CORS_ORIGINS", "[]")
    if os.environ.get("ENV") is None:
        monkeypatch.setenv("ENV", "prod")
    with TestClient(create_app()) as http:
        yield http


@pytest.fixture
def account():
    return {
        "nama_pemilik": "Pemilik Uji",
        "nama_toko": "Toko Uji",
        "email": "seller@example.com",
        "password": "SandiUji123!",
    }


@pytest.fixture
def pg_client(monkeypatch, tmp_path):
    from sqlalchemy.engine import make_url

    raw = os.environ.get("A2_TEST_POSTGRES_URL")
    if not raw:
        pytest.skip("PostgreSQL seam run separately with A2_TEST_POSTGRES_URL")
    schema = "a2_test_" + uuid4().hex
    engine = create_engine(raw, hide_parameters=True)
    with engine.begin() as connection:
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
    url = make_url(raw).update_query_dict({"options": f"-csearch_path={schema}"})
    monkeypatch.setenv("DATABASE_URL", url.render_as_string(hide_password=False))
    monkeypatch.setenv("JWT_SECRET", secrets.token_urlsafe(48))
    monkeypatch.setenv("XENDIT_API_KEY", "")
    monkeypatch.setenv("XENDIT_WEBHOOK_TOKEN", "")
    monkeypatch.setenv("AUTO_CREATE_TABLES", "true")
    monkeypatch.setenv("UPLOADS_DIR", str(tmp_path / "uploads"))
    try:
        with TestClient(create_app()) as http:
            yield http
    finally:
        with engine.begin() as connection:
            connection.execute(text(f'DROP SCHEMA "{schema}" CASCADE'))
        engine.dispose()

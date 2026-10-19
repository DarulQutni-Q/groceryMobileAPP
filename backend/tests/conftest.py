import secrets

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client(monkeypatch, tmp_path):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'auth.db'}")
    monkeypatch.setenv("JWT_SECRET", secrets.token_urlsafe(48))
    monkeypatch.setenv("GOOGLE_CLIENT_ID", "")
    monkeypatch.setenv("AUTO_CREATE_TABLES", "true")
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

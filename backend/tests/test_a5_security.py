import pytest
from pydantic import ValidationError
from test_toko import register

from app.core.config import Settings


@pytest.mark.parametrize(
    "origin", ["*", "https://*.example.com", "https://seller.example.com/path"]
)
def test_cors_configuration_rejects_non_origins_in_production(origin):
    with pytest.raises(ValidationError):
        Settings(database_url="sqlite://", jwt_secret="a" * 48, env="prod", cors_origins=[origin])


@pytest.mark.parametrize("path", ["/docs", "/redoc", "/openapi.json", "/docs/oauth2-redirect"])
def test_api_debug_documentation_is_hidden_in_production(client, path):
    client.app.state.settings.env = "prod"
    result = client.get(path)
    assert result.status_code == 404
    assert result.headers["x-request-id"]


def test_dev_documentation_and_prod_internal_guard(client):
    client.app.state.settings.env = "dev"
    assert client.get("/docs").status_code == 200
    client.app.state.settings.env = "prod"
    assert client.post("/pesanan/internal/test").status_code == 404


def test_cors_exposes_request_id_only_to_configured_origin(client, account):
    client.app.state.settings.cors_origins = ["https://seller.example.com"]
    response = client.get(
        "/toko/me", headers={**register(client, account), "Origin": "https://seller.example.com"}
    )
    assert response.headers["access-control-allow-origin"] == "https://seller.example.com"
    assert "X-Request-ID" in response.headers["access-control-expose-headers"]

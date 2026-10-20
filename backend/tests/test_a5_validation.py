import pytest
from pydantic import ValidationError
from test_toko import register

from app.schemas.auth import FcmTokenRequest


@pytest.mark.parametrize(
    "route,payload",
    [
        (
            "/produk",
            {"nama": "Barang\0uji", "harga": 10, "stok": 1, "satuan": "pcs", "kategori": "Beras"},
        ),
        ("/toko/me", {"nama": "Toko\0uji"}),
        ("/auth/fcm-token", {"fcm_token": "token\0uji"}),
        ("/auth/fcm-token", {"fcm_token": "   "}),
    ],
)
def test_unsafe_text_is_rejected_before_database(client, account, route, payload):
    headers = register(client, account)
    method = "POST" if route == "/produk" else "PUT" if route == "/toko/me" else "PATCH"
    response = client.request(method, route, json=payload, headers=headers)
    assert response.status_code == 422
    assert "message" in response.json()["detail"][0]


@pytest.mark.parametrize("query", [{"q": "Beras\0uji"}, {"kategori": "Beras\0uji"}])
def test_unsafe_search_is_rejected_before_database(client, account, query):
    response = client.get("/produk", params=query, headers=register(client, account))
    assert response.status_code == 422


def test_phone_format_is_checked(client, account):
    response = client.post("/auth/register", json={**account, "phone": "abcdef"})
    assert response.status_code == 422
    assert "telepon" in response.text.lower()


@pytest.mark.parametrize(
    "body,expected",
    [
        ("{", "JSON tidak valid"),
        ("{}", "Nama wajib diisi"),
        (
            '{"nama":"a","harga":-1,"stok":0,"satuan":"kg","kategori":"a"}',
            "Harga harus lebih dari 0",
        ),
        (
            '{"nama":"a","harga":2147483648,"stok":0,"satuan":"kg","kategori":"a"}',
            "Harga maksimal 2147483647",
        ),
    ],
)
def test_validation_messages_are_specific_indonesian(client, account, body, expected):
    response = client.post(
        "/produk",
        content=body,
        headers={**register(client, account), "Content-Type": "application/json"},
    )
    assert response.status_code == 422
    assert expected in response.text


def test_query_and_uuid_errors_explain_allowed_values(client, account):
    headers = register(client, account)
    cases = [
        ("/laporan/ringkasan?range=1h", "7h atau 30h"),
        ("/laporan/produk-terlaris?limit=200", "maksimal 100"),
        ("/produk/invalid", "UUID"),
        ("/toko/me/status", "buka atau tutup"),
    ]
    for path, expected in cases:
        response = (
            client.patch(path, json={"status": "invalid"}, headers=headers)
            if path == "/toko/me/status"
            else client.get(path, headers=headers)
        )
        assert response.status_code == 422
        assert expected in response.text


def test_deeply_nested_wrong_field_type_is_validation_error():
    value = 0
    for _ in range(1000):
        value = [value]
    with pytest.raises(ValidationError):
        FcmTokenRequest.model_validate({"fcm_token": value})

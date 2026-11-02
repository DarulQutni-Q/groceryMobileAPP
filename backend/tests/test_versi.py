"""Force-update: endpoint publik, default tidak menggerbang, dan
perbandingan semver (termasuk fail-open untuk versi tak valid)."""

from app.services.versi import parse_versi, wajib_update


def test_parse_dan_banding():
    assert parse_versi("1.2.3") == (1, 2, 3)
    assert parse_versi("1.2") == (1, 2, 0)
    assert parse_versi("0.1.0+1") == (0, 1, 0)
    assert parse_versi("abc") is None
    assert parse_versi("") is None
    assert wajib_update("0.1.0", "0.2.0") is True
    assert wajib_update("0.2.0", "0.2.0") is False
    assert wajib_update("1.0.0", "0.9.9") is False
    assert wajib_update("rusak", "9.9.9") is False


def test_endpoint_default_tidak_menggerbang(client):
    response = client.get("/versi-minimum", params={"aplikasi": "customer", "versi": "0.1.0"})
    assert response.status_code == 200
    body = response.json()
    assert body["versi_minimum"] == "0.0.0"
    assert body["wajib_update"] is False


def test_endpoint_aplikasi_tak_valid_ditolak(client):
    assert client.get("/versi-minimum", params={"aplikasi": "admin"}).status_code == 422

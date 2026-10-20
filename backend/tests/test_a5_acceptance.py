import json
import os
from pathlib import Path

import pytest
from test_pesanan import order, product, seller
from test_upload import photo

BODY_ROUTES = [
    ("POST", "/auth/register"),
    ("POST", "/auth/login"),
    ("POST", "/auth/google"),
    ("POST", "/auth/refresh"),
    ("PATCH", "/auth/fcm-token"),
    ("PUT", "/toko/me"),
    ("PATCH", "/toko/me/status"),
    ("PUT", "/toko/me/jam-buka"),
    ("POST", "/produk"),
    ("PUT", "/produk/{produk_id}"),
    ("PATCH", "/pesanan/{pesanan_id}/tolak"),
    ("PATCH", "/pesanan/{pesanan_id}/status"),
    ("POST", "/pesanan/internal/test"),
]


@pytest.fixture(params=["client", "pg_client"])
def api_case(request, monkeypatch, account):
    monkeypatch.setenv("ENV", "dev")
    client = request.getfixturevalue(request.param)
    headers = seller(client, account)
    produk = product(client, headers)
    pesanan = order(client, headers, produk["id"])
    return client, headers, {"produk_id": produk["id"], "pesanan_id": pesanan["id"]}


def save_rows(client, name, rows):
    target = os.environ.get("A5_REPORT_DIR")
    if target:
        path = Path(target)
        path.mkdir(parents=True, exist_ok=True)
        backend = client.app.state.engine.dialect.name
        (path / f"{backend}-{name}.json").write_text(json.dumps(rows, indent=2) + "\n")


@pytest.mark.parametrize("method,route", BODY_ROUTES)
def test_each_body_endpoint_handles_malformed_inputs(api_case, method, route):
    client, headers, ids = api_case
    rows = []
    for label, body, expected in [
        ("JSON rusak", "{", 422),
        ("array sebagai objek", "[]", 422),
        ("string kosong", '""', 422),
        ("angka negatif sebagai body", "-1", 422),
        ("JSON terlalu dalam", "[" * 1500 + "0" + "]" * 1500, 400),
    ]:
        response = client.request(
            method,
            route.format(**ids),
            content=body,
            headers={**headers, "Content-Type": "application/json"},
        )
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": label,
                "expected": expected,
                "actual": response.status_code,
            }
        )
        assert response.status_code == expected
        assert response.headers["x-request-id"]
    save_rows(client, method + route.replace("/", "-"), rows)


def test_all_business_routes_require_jwt_and_invalid_identifiers_are_422(api_case):
    client, headers, ids = api_case
    routes = [
        ("GET", "/auth/me"),
        ("PATCH", "/auth/fcm-token"),
        ("GET", "/toko/me"),
        ("PUT", "/toko/me"),
        ("PATCH", "/toko/me/status"),
        ("GET", "/toko/me/jam-buka"),
        ("PUT", "/toko/me/jam-buka"),
        ("GET", "/produk"),
        ("POST", "/produk"),
        ("GET", "/produk/{produk_id}"),
        ("PUT", "/produk/{produk_id}"),
        ("DELETE", "/produk/{produk_id}"),
        ("PATCH", "/produk/{produk_id}/toggle"),
        ("POST", "/produk/{produk_id}/foto"),
        ("GET", "/pesanan"),
        ("POST", "/pesanan/internal/test"),
        ("GET", "/pesanan/{pesanan_id}"),
        ("PATCH", "/pesanan/{pesanan_id}/terima"),
        ("PATCH", "/pesanan/{pesanan_id}/tolak"),
        ("PATCH", "/pesanan/{pesanan_id}/status"),
        ("PATCH", "/pesanan/{pesanan_id}/urungkan"),
        ("GET", "/laporan/ringkasan"),
        ("GET", "/laporan/produk-terlaris"),
    ]
    rows = []
    for method, route in routes:
        response = client.request(method, route.format(**ids))
        assert response.status_code == 401
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": "tanpa JWT",
                "expected": 401,
                "actual": response.status_code,
            }
        )
    for method, route in routes:
        if "{" not in route:
            continue
        response = client.request(
            method, route.format(produk_id="ngawur", pesanan_id="ngawur"), headers=headers, json={}
        )
        assert response.status_code == 422
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": "UUID ngawur",
                "expected": 422,
                "actual": response.status_code,
            }
        )
    save_rows(client, "jwt-and-uuid", rows)


def test_nul_text_never_reaches_postgres(api_case):
    client, headers, ids = api_case
    checks = [
        (
            "POST",
            "/auth/register",
            {
                "nama_pemilik": "Nul\0uji",
                "nama_toko": "Toko",
                "email": "nul@example.com",
                "password": "SandiUji123!",
            },
        ),
        ("PATCH", "/auth/fcm-token", {"fcm_token": "uji\0token"}),
        ("PUT", "/toko/me", {"alamat": "Jalan\0uji"}),
        (
            "POST",
            "/produk",
            {"nama": "Beras\0uji", "harga": 1, "stok": 1, "satuan": "pcs", "kategori": "Beras"},
        ),
        ("PATCH", "/pesanan/{pesanan_id}/tolak", {"alasan": "Tidak\0tersedia"}),
        ("POST", "/pesanan/internal/test", {"catatan": "Uji\0catatan"}),
    ]
    rows = []
    for method, route, payload in checks:
        response = client.request(method, route.format(**ids), headers=headers, json=payload)
        assert response.status_code == 422
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": "teks NUL",
                "expected": 422,
                "actual": response.status_code,
            }
        )
    for field in ["q", "kategori"]:
        response = client.get("/produk", params={field: "Beras\0uji"}, headers=headers)
        assert response.status_code == 422
        rows.append(
            {
                "method": "GET",
                "endpoint": "/produk",
                "input": field + " NUL",
                "expected": 422,
                "actual": response.status_code,
            }
        )
    save_rows(client, "nul", rows)


def test_huge_integer_json_does_not_crash_routes_without_body_schema(api_case):
    client, headers, ids = api_case
    rows = []
    for method, route in [
        ("PATCH", "/produk/{produk_id}/toggle"),
        ("PATCH", "/pesanan/{pesanan_id}/terima"),
        ("DELETE", "/produk/{produk_id}"),
    ]:
        response = client.request(
            method,
            route.format(**ids),
            content="9" * 5000,
            headers={**headers, "Content-Type": "application/json"},
        )
        assert response.status_code == 400
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": "integer JSON 5000 digit",
                "expected": 400,
                "actual": response.status_code,
            }
        )
    save_rows(client, "huge-integer", rows)


def test_successful_public_api_journey(api_case, account):
    client, _, _ = api_case
    rows, headers = [], {}

    def call(method, route, label="input valid", expected=200, **kwargs):
        response = client.request(method, route, headers=headers, **kwargs)
        rows.append(
            {
                "method": method,
                "endpoint": route,
                "input": label,
                "expected": expected,
                "actual": response.status_code,
            }
        )
        assert response.status_code == expected
        assert response.headers["x-request-id"]
        return response

    payload = {**account, "email": "journey@example.com"}
    tokens = call("POST", "/auth/register", json=payload).json()
    call("POST", "/auth/login", json={"email": payload["email"], "password": payload["password"]})
    call("POST", "/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    headers["Authorization"] = "Bearer " + tokens["access_token"]
    call("GET", "/auth/me")
    call("PATCH", "/auth/fcm-token", json={"fcm_token": "fcm-valid-test-token"})
    call(
        "POST",
        "/auth/google",
        label="Google belum dikonfigurasi",
        expected=503,
        json={"id_token": "invalid-test-token"},
    )
    call("GET", "/health")
    call("GET", "/toko/me")
    call("PUT", "/toko/me", json={"nama": "Toko Journey", "alamat": "Jalan Uji 1"})
    call("PATCH", "/toko/me/status", json={"status": "buka"})
    call("PATCH", "/toko/me/status", json={"status": "tutup"})
    days = call("GET", "/toko/me/jam-buka").json()
    call("PUT", "/toko/me/jam-buka", json=days)
    produk = call(
        "POST",
        "/produk",
        json={"nama": "Beras", "harga": 15000, "stok": 5, "satuan": "kg", "kategori": "Beras"},
    ).json()
    path = "/produk/" + produk["id"]
    call("GET", "/produk")
    call("GET", "/produk?page=1&per_page=200")
    call("GET", path)
    call("PUT", path, json={"harga": 16000})
    call("PATCH", path + "/toggle")
    url = call("POST", path + "/foto", files={"file": ("uji.png", photo(), "image/png")}).json()[
        "foto_url"
    ]
    call("GET", url)
    first = call(
        "POST", "/pesanan/internal/test", json={"items": [{"produk_id": produk["id"], "qty": 1}]}
    ).json()
    call("GET", "/pesanan")
    call("GET", "/pesanan?page=1")
    order_path = "/pesanan/" + first["id"]
    call("GET", order_path)
    call("PATCH", order_path + "/terima")
    call("PATCH", order_path + "/urungkan")
    call("PATCH", order_path + "/terima")
    for step in ["dikemas", "diantar", "selesai"]:
        call("PATCH", order_path + "/status", json={"status": step})
    rejected = call(
        "POST", "/pesanan/internal/test", json={"items": [{"produk_id": produk["id"], "qty": 1}]}
    ).json()
    call("PATCH", "/pesanan/" + rejected["id"] + "/tolak", json={"alasan": "Stok Habis"})
    call("GET", "/laporan/ringkasan?range=7h")
    call("GET", "/laporan/produk-terlaris?range=30h&limit=5")
    call("DELETE", path)
    save_rows(client, "successful-journey", rows)

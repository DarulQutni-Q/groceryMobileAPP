import io

from PIL import Image


def photo(format="PNG"):
    data = io.BytesIO()
    Image.new("RGB", (16, 16), "green").save(data, format=format)
    return data.getvalue()


def register(client, account):
    result = client.post("/auth/register", json=account)
    assert result.status_code == 200
    return {"Authorization": f"Bearer {result.json()['access_token']}"}


def test_register_creates_private_store_with_safe_defaults(client, account):
    headers = register(client, account)
    result = client.get("/toko/me", headers=headers)
    assert result.status_code == 200
    toko = result.json()
    assert toko["nama"] == account["nama_toko"]
    assert toko["status"] == "tutup"
    assert toko["radius_km"] == 5
    assert toko["kategori"] == []
    assert toko["metode_kirim"] == []
    assert toko["alamat"] == ""
    assert "password_hash" not in result.text
    assert client.get("/toko/me").status_code == 401


def test_profile_update_is_owned_and_keeps_auth_name_in_sync(client, account):
    headers = register(client, account)
    update = {
        "nama": "Toko Baru",
        "alamat": "Jalan Uji 10",
        "telepon": "081234567890",
        "kategori": ["Sembako", "Sayur"],
        "radius_km": 8,
        "metode_kirim": ["Instant"],
        "rekening_bank": "BRI 123456",
    }
    response = client.put("/toko/me", headers=headers, json=update)
    assert response.status_code == 200
    assert response.json()["nama"] == "Toko Baru"
    assert client.get("/auth/me", headers=headers).json()["nama_toko"] == "Toko Baru"
    for invalid in [{"radius_km": 11}, {"kategori": ["Tidak ada"]}, {"nama": " "}]:
        assert client.put("/toko/me", headers=headers, json=invalid).status_code == 422
    account["email"] = "other@example.com"
    other = register(client, account)
    assert client.get("/toko/me", headers=other).json()["nama"] == account["nama_toko"]
    assert (
        client.patch("/toko/me/status", headers=headers, json={"status": "buka"}).json()["status"]
        == "buka"
    )
    assert client.get("/toko/me", headers=other).json()["status"] == "tutup"


def test_opening_hours_require_seven_unique_valid_days_and_replace_atomically(client, account):
    headers = register(client, account)
    response = client.get("/toko/me/jam-buka", headers=headers)
    assert response.status_code == 200
    days = response.json()
    assert len(days) == 7
    assert all(day["is_tutup"] for day in days)
    days[0].update(is_tutup=False, jam_buka="07:00:00", jam_tutup="23:00:00")
    assert client.put("/toko/me/jam-buka", headers=headers, json=days).status_code == 200
    invalid = [dict(day) for day in days]
    invalid[0]["jam_tutup"] = "06:00:00"
    assert client.put("/toko/me/jam-buka", headers=headers, json=invalid).status_code == 422
    assert client.put("/toko/me/jam-buka", headers=headers, json=days[:-1]).status_code == 422
    invalid = [dict(days[0]) for _ in range(7)]
    assert client.put("/toko/me/jam-buka", headers=headers, json=invalid).status_code == 422
    saved = client.get("/toko/me/jam-buka", headers=headers).json()
    assert saved[0]["jam_tutup"] == "23:00:00"


def test_opening_hours_reject_offsets_as_local_time(client, account):
    headers = register(client, account)
    days = client.get("/toko/me/jam-buka", headers=headers).json()
    days[0].update(is_tutup=False, jam_buka="08:00:00+07:00", jam_tutup="23:00:00")
    result = client.put("/toko/me/jam-buka", headers=headers, json=days)
    assert result.status_code == 422
    assert "Jam" in result.text


def test_google_fallback_store_name_stays_within_model_limit(client, monkeypatch):
    client.app.state.settings.google_client_id = "configured-client-id"
    monkeypatch.setattr(
        "google.oauth2.id_token.verify_oauth2_token",
        lambda *args: {
            "sub": "long-google-name",
            "email": "long@example.com",
            "email_verified": True,
            "name": "A" * 120,
        },
    )
    result = client.post("/auth/google", json={"id_token": "verified-by-google-library"})
    assert result.status_code == 200
    headers = {"Authorization": f"Bearer {result.json()['access_token']}"}
    toko = client.get("/toko/me", headers=headers).json()
    assert len(toko["nama"]) <= 120


def test_upload_logo_stores_url_and_replaces_old_logo(client, account):
    headers = register(client, account)
    result = client.post(
        "/toko/me/logo",
        headers=headers,
        files={"file": ("logo.png", photo(), "image/png")},
    )
    assert result.status_code == 200
    toko = result.json()
    assert toko["logo_url"] is not None
    assert toko["logo_url"].startswith("/uploads/")
    first_url = toko["logo_url"]
    assert client.get(first_url).status_code == 200
    result2 = client.post(
        "/toko/me/logo",
        headers=headers,
        files={"file": ("logo2.jpg", photo("JPEG"), "image/jpeg")},
    )
    assert result2.status_code == 200
    second_url = result2.json()["logo_url"]
    assert second_url != first_url
    assert client.get(second_url).status_code == 200
    assert client.get(first_url).status_code == 404


def test_upload_logo_rejects_invalid_format(client, account):
    headers = register(client, account)
    for filename, data, mime in [
        ("bad.png", b"not an image", "image/png"),
        ("bad.svg", b"<svg/>", "image/svg+xml"),
        ("bad.jpg", photo("JPEG")[:-20], "image/jpeg"),
    ]:
        result = client.post(
            "/toko/me/logo",
            headers=headers,
            files={"file": (filename, data, mime)},
        )
        assert result.status_code == 422


def test_upload_logo_rejects_oversized_file(client, account):
    headers = register(client, account)
    big = photo() + b"0" * (5 * 1024 * 1024)
    result = client.post(
        "/toko/me/logo",
        headers=headers,
        files={"file": ("big.png", big, "image/png")},
    )
    assert result.status_code == 422


def test_upload_logo_requires_auth(client):
    result = client.post(
        "/toko/me/logo",
        files={"file": ("logo.png", photo(), "image/png")},
    )
    assert result.status_code == 401

def test_register_returns_session_and_private_seller_profile(client, account):
    response = client.post("/auth/register", json=account)
    assert response.status_code == 200
    tokens = response.json()
    assert tokens["token_type"] == "bearer"
    assert tokens["access_token"] != tokens["refresh_token"]
    profile = client.get("/auth/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    assert profile.status_code == 200
    assert profile.json()["nama"] == account["nama_pemilik"]
    assert profile.json()["nama_toko"] == account["nama_toko"]
    assert profile.json()["role"] == "seller"
    assert "password_hash" not in profile.json()
    assert "password" not in profile.json()


def test_duplicate_email_is_rejected_case_insensitively(client, account):
    assert client.post("/auth/register", json=account).status_code == 200
    account["email"] = account["email"].upper()
    result = client.post("/auth/register", json=account)
    assert result.status_code == 400
    assert result.json()["detail"] == "Email sudah terdaftar"


def test_password_validation_is_indonesian_and_does_not_echo_input(client, account):
    for invalid in ["123", "abcdefgh!", "abcdefgh1", "12345678!", "A1!" * 8]:
        account["password"] = invalid
        result = client.post("/auth/register", json=account)
        assert result.status_code == 422
        assert "Kata sandi" in result.text
        assert invalid not in result.text


def test_login_refresh_and_token_types(client, account):
    assert client.post("/auth/register", json=account).status_code == 200
    login = client.post(
        "/auth/login",
        json={
            "email": account["email"],
            "password": account["password"],
        },
    )
    assert login.status_code == 200
    tokens = login.json()
    refreshed = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refreshed.status_code == 200
    assert refreshed.json()["access_token"] != tokens["access_token"]
    assert (
        client.post(
            "/auth/refresh",
            json={
                "refresh_token": tokens["access_token"],
            },
        ).status_code
        == 401
    )
    assert (
        client.get(
            "/auth/me",
            headers={
                "Authorization": f"Bearer {tokens['refresh_token']}",
            },
        ).status_code
        == 401
    )


def test_wrong_password_and_missing_token_are_unauthorized(client, account):
    client.post("/auth/register", json=account)
    result = client.post(
        "/auth/login",
        json={
            "email": account["email"],
            "password": "Salah123!",
        },
    )
    assert result.status_code == 401
    assert result.json()["detail"] == "Email atau kata sandi salah"
    assert client.get("/auth/me").status_code == 401


def test_login_is_limited_per_ip_and_ignores_spoofed_forwarded_headers(client):
    for _ in range(5):
        assert (
            client.post(
                "/auth/login",
                json={
                    "email": "missing@example.com",
                    "password": "Salah123!",
                },
            ).status_code
            == 401
        )
    limited = client.post(
        "/auth/login",
        json={
            "email": "missing@example.com",
            "password": "Salah123!",
        },
        headers={"X-Forwarded-For": "203.0.113.9"},
    )
    assert limited.status_code == 429
    assert "Terlalu banyak" in limited.json()["detail"]


def test_fcm_update_requires_session_and_is_saved(client, account):
    assert client.patch("/auth/fcm-token", json={"fcm_token": "uji"}).status_code == 401
    tokens = client.post("/auth/register", json=account).json()
    result = client.patch(
        "/auth/fcm-token",
        json={"fcm_token": "fcm-uji"},
        headers={
            "Authorization": f"Bearer {tokens['access_token']}",
        },
    )
    assert result.status_code == 200
    assert result.json() == {"message": "Token notifikasi tersimpan"}


def test_google_without_configuration_returns_clear_error(client):
    result = client.post("/auth/google", json={"id_token": "invalid"})
    assert result.status_code == 503
    assert result.json()["detail"] == "Login Google belum dikonfigurasi"


def test_cors_rejects_unregistered_origin_and_disallowed_method(client):
    result = client.options(
        "/auth/login",
        headers={
            "Origin": "https://untrusted.example.com",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert result.status_code == 400
    assert "access-control-allow-origin" not in result.headers
    client.app.state.settings.cors_origins = ["https://seller.example.com"]
    allowed = client.options(
        "/auth/login",
        headers={
            "Origin": "https://seller.example.com",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert allowed.headers["access-control-allow-origin"] == "https://seller.example.com"
    assert (
        client.options(
            "/auth/login",
            headers={
                "Origin": "https://seller.example.com",
                "Access-Control-Request-Method": "DELETE",
            },
        ).status_code
        == 400
    )


def test_health_checks_database_and_adds_request_id(client):
    result = client.get("/health")
    assert result.status_code == 200
    assert result.json()["database"] == "ok"
    assert result.headers["x-request-id"]


def test_google_verifies_audience_and_does_not_link_email_accounts(client, account, monkeypatch):
    client.post("/auth/register", json=account)
    client.app.state.settings.google_client_id = "configured-client-id"

    def verified(token, transport, audience):
        assert token == "signed-google-token"
        assert audience == "configured-client-id"
        return {"sub": "google-account-1", "email": account["email"], "email_verified": True}

    monkeypatch.setattr("google.oauth2.id_token.verify_oauth2_token", verified)
    result = client.post("/auth/google", json={"id_token": "signed-google-token"})
    assert result.status_code == 400
    assert "metode login semula" in result.json()["detail"]


def test_fcm_and_password_are_persisted_safely(client, account, tmp_path):
    import sqlite3
    from contextlib import closing

    tokens = client.post("/auth/register", json=account).json()
    client.patch(
        "/auth/fcm-token",
        json={"fcm_token": "token-uji"},
        headers={
            "Authorization": f"Bearer {tokens['access_token']}",
        },
    )
    with closing(sqlite3.connect(tmp_path / "auth.db")) as db:
        password_hash, fcm = db.execute("SELECT password_hash, fcm_token FROM users").fetchone()
    assert password_hash.startswith("$2b$")
    assert password_hash != account["password"]
    assert fcm == "token-uji"


def test_verified_google_creates_seller_and_reuses_stable_subject(client, monkeypatch):
    client.app.state.settings.google_client_id = "configured-client-id"
    claims = {
        "sub": "stable-google-subject",
        "email": "google@example.com",
        "email_verified": True,
        "name": "Pemilik Google",
    }
    monkeypatch.setattr("google.oauth2.id_token.verify_oauth2_token", lambda *args: claims)
    first = client.post("/auth/google", json={"id_token": "verified-by-google-library"})
    assert first.status_code == 200
    profile = client.get(
        "/auth/me",
        headers={
            "Authorization": f"Bearer {first.json()['access_token']}",
        },
    ).json()
    assert profile["role"] == "seller"
    assert profile["nama"] == "Pemilik Google"
    claims["email"] = "updated-google@example.com"
    second = client.post("/auth/google", json={"id_token": "verified-by-google-library"})
    assert second.status_code == 200
    assert (
        client.get(
            "/auth/me",
            headers={
                "Authorization": f"Bearer {second.json()['access_token']}",
            },
        ).json()["id"]
        == profile["id"]
    )


def test_unverified_google_email_is_rejected(client, monkeypatch):
    client.app.state.settings.google_client_id = "configured-client-id"
    monkeypatch.setattr(
        "google.oauth2.id_token.verify_oauth2_token",
        lambda *args: {
            "sub": "unverified-subject",
            "email": "unverified@example.com",
            "email_verified": False,
        },
    )
    assert client.post("/auth/google", json={"id_token": "unverified"}).status_code == 401


def test_phone_is_unique_and_public_registration_cannot_choose_admin(client, account):
    account.update(phone="+628123456789", role="admin")
    first = client.post("/auth/register", json=account)
    assert first.status_code == 200
    assert (
        client.get(
            "/auth/me",
            headers={
                "Authorization": f"Bearer {first.json()['access_token']}",
            },
        ).json()["role"]
        == "seller"
    )
    account["email"] = "different@example.com"
    duplicate = client.post("/auth/register", json=account)
    assert duplicate.status_code == 400
    assert duplicate.json()["detail"] == "Nomor telepon sudah terdaftar"


def test_expired_missing_expiry_and_tampered_tokens_are_rejected(client, account):
    from jose import jwt

    token = client.post("/auth/register", json=account).json()["access_token"]
    claims = jwt.get_unverified_claims(token)
    secret = client.app.state.settings.jwt_secret.get_secret_value()
    expired = jwt.encode({**claims, "exp": 1}, secret, algorithm="HS256")
    without_exp = jwt.encode(
        {k: v for k, v in claims.items() if k != "exp"}, secret, algorithm="HS256"
    )
    parts = token.split(".")
    parts[2] = ("x" if parts[2][0] != "x" else "y") + parts[2][1:]
    for invalid in [expired, without_exp, ".".join(parts)]:
        assert (
            client.get(
                "/auth/me",
                headers={
                    "Authorization": f"Bearer {invalid}",
                },
            ).status_code
            == 401
        )

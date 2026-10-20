from test_toko import register


def assert_limited(response):
    assert response.status_code == 429
    seconds = int(response.headers["retry-after"])
    assert 1 <= seconds <= 60
    assert response.json()["detail"] == (
        f"Terlalu banyak permintaan, coba lagi dalam {seconds} detik"
    )


def test_login_sixth_attempt_has_remaining_seconds(client):
    payload = {"email": "missing@example.com", "password": "Wrong123!"}
    for _ in range(5):
        assert client.post("/auth/login", json=payload).status_code == 401
    assert_limited(client.post("/auth/login", json=payload))


def test_registration_fourth_attempt_is_limited_by_peer_ip(client, account):
    assert client.post("/auth/register", json=account).status_code == 200
    for _ in range(2):
        assert client.post("/auth/register", json=account).status_code == 400
    assert_limited(
        client.post("/auth/register", json=account, headers={"X-Forwarded-For": "203.0.113.42"})
    )


def test_mutations_share_quota_per_verified_user_across_endpoints(client, account):
    headers = register(client, account)
    other = register(client, {**account, "email": "other@example.com"})
    for _ in range(60):
        response = client.patch("/auth/fcm-token", json={"fcm_token": "test"}, headers=headers)
        assert response.status_code == 200
    assert_limited(client.patch("/toko/me/status", json={"status": "buka"}, headers=headers))
    assert (
        client.patch("/toko/me/status", json={"status": "buka"}, headers=other).status_code == 200
    )
    assert client.get("/toko/me", headers=headers).status_code == 200
    assert client.patch("/auth/fcm-token", json={"fcm_token": "test"}).status_code == 401


def test_unavailable_rate_limit_storage_returns_503(monkeypatch, request):
    monkeypatch.setenv("RATE_LIMIT_STORAGE_URI", "redis://127.0.0.1:1/0?socket_connect_timeout=1")
    client = request.getfixturevalue("client")
    response = client.post("/auth/login", json={"email": "missing@example.com", "password": "test"})
    assert response.status_code == 503
    assert "coba lagi" in response.json()["detail"].lower()

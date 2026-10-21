import pytest
from sqlalchemy import func, select

from app.models.toko import Toko
from app.models.user import User


@pytest.fixture(params=["client", "pg_client"])
def customer_client(request):
    return request.getfixturevalue(request.param)


def signup(client, **overrides):
    return client.post(
        "/auth/register",
        json={
            "email": "pembeli@example.com",
            "password": "SandiCustomer123!",
            "role": "customer",
            **overrides,
        },
    )


def test_customer_registration_session_refresh_and_no_store(customer_client):
    client = customer_client
    response = signup(client)
    assert response.status_code == 200
    tokens = response.json()
    headers = {"Authorization": "Bearer " + tokens["access_token"]}
    profile = client.get("/auth/me", headers=headers)
    assert profile.status_code == 200
    assert profile.json()["role"] == "customer"
    assert profile.json()["nama"] == "pembeli"
    assert profile.json()["nama_toko"] is None
    assert (
        client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 200
    )
    with client.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(Toko)) == 0
    assert (
        client.patch(
            "/auth/fcm-token", headers=headers, json={"fcm_token": "customer-test-fcm"}
        ).status_code
        == 200
    )
    for route in [
        "/toko/me",
        "/toko/me/jam-buka",
        "/laporan/ringkasan",
        "/laporan/produk-terlaris",
    ]:
        assert client.get(route, headers=headers).status_code == 403
    catalog = client.get("/produk", headers=headers)
    assert catalog.status_code == 200
    assert catalog.json()["data"] == []
    orders = client.get("/pesanan", headers=headers)
    assert orders.status_code == 200
    assert orders.json()["data"] == []


def test_admin_role_is_rejected_before_account_creation(customer_client):
    client = customer_client
    assert signup(client, role="admin").status_code == 422
    assert (
        client.post("/auth/google", json={"id_token": "invalid", "role": "admin"}).status_code
        == 422
    )
    with client.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(User)) == 0


def test_customer_google_role_and_existing_account_are_immutable(customer_client, monkeypatch):
    client = customer_client
    client.app.state.settings.google_client_id = "test-client"
    monkeypatch.setattr(
        "google.oauth2.id_token.verify_oauth2_token",
        lambda *args: {
            "sub": "customer-google-subject",
            "email": "customer-google@example.com",
            "email_verified": True,
            "name": "Pembeli Google",
        },
    )
    payload = {"id_token": "verified-google-token", "role": "customer"}
    response = client.post("/auth/google", json=payload)
    assert response.status_code == 200
    profile = client.get(
        "/auth/me", headers={"Authorization": "Bearer " + response.json()["access_token"]}
    )
    assert profile.json()["role"] == "customer"
    assert profile.json()["nama"] == "Pembeli Google"
    assert client.post("/auth/google", json={**payload, "role": "seller"}).status_code == 401
    assert client.post("/auth/google", json=payload).status_code == 200
    with client.app.state.sessions() as db:
        assert db.scalar(select(func.count()).select_from(Toko)) == 0


def test_customer_email_login_is_explicit_and_seller_client_does_not_accept_it(customer_client):
    client = customer_client
    assert signup(client).status_code == 200
    payload = {"email": "pembeli@example.com", "password": "SandiCustomer123!"}
    assert client.post("/auth/login", json=payload).status_code == 401
    assert client.post("/auth/login", json={**payload, "role": "customer"}).status_code == 200


def test_phone_login_normalization_password_and_unknown_account(customer_client):
    client = customer_client
    result = signup(client, phone="081234567890")
    assert result.status_code == 200
    user = client.get(
        "/auth/me", headers={"Authorization": "Bearer " + result.json()["access_token"]}
    ).json()
    assert user["phone"] == "+6281234567890"
    for phone in ["081234567890", "6281234567890", "+6281234567890"]:
        response = client.post(
            "/auth/login/phone", json={"phone": phone, "password": "SandiCustomer123!"}
        )
        assert response.status_code == 200
    wrong = client.post("/auth/login/phone", json={"phone": "081234567890", "password": "wrong"})
    unknown = client.post("/auth/login/phone", json={"phone": "081234567899", "password": "wrong"})
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()


def test_customer_phone_uniqueness_and_seller_phone_isolation(customer_client, account):
    client = customer_client
    seller = client.post("/auth/register", json={**account, "phone": "+6282222222222"})
    assert seller.status_code == 200
    assert (
        client.post(
            "/auth/login/phone", json={"phone": "082222222222", "password": account["password"]}
        ).status_code
        == 401
    )
    assert signup(client, phone="081234567890").status_code == 200
    duplicate = signup(client, email="other@example.com", phone="+6281234567890")
    assert duplicate.status_code == 400
    assert "telepon" in duplicate.text.lower()

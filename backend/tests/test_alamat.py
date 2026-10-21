from uuid import uuid4

import pytest


@pytest.fixture(params=["client", "pg_client"])
def addresses(request, account):
    client = request.getfixturevalue(request.param)
    headers = []
    for i in range(2):
        result = client.post(
            "/auth/register",
            json={
                "email": f"alamat{i}@example.com",
                "password": "SandiUji123!",
                "role": "customer",
            },
        )
        assert result.status_code == 200
        headers.append({"Authorization": "Bearer " + result.json()["access_token"]})
    seller = client.post("/auth/register", json=account)
    headers.append({"Authorization": "Bearer " + seller.json()["access_token"]})
    return client, headers


def payload(**extra):
    return {
        "label": "Rumah",
        "nama_penerima": "Darul",
        "no_hp": "081234567890",
        "alamat_lengkap": "Jalan Melati 10",
        "patokan": "Pagar hijau",
        **extra,
    }


def test_address_crud_primary_and_owner_isolation(addresses):
    client, (buyer, other, seller) = addresses
    assert client.get("/alamat").status_code == 401
    assert client.get("/alamat", headers=seller).status_code == 403
    first = client.post("/alamat", headers=buyer, json=payload())
    assert first.status_code == 201
    a = first.json()
    assert a["is_utama"] is True
    second = client.post("/alamat", headers=buyer, json=payload(label="Kantor")).json()
    assert second["is_utama"] is False
    assert client.get("/alamat", headers=other).json() == []
    for method, suffix in [("put", ""), ("delete", ""), ("patch", "/jadikan-utama")]:
        kwargs = {"json": payload()} if method == "put" else {}
        assert (
            getattr(client, method)(
                f"/alamat/{a['id']}{suffix}", headers=other, **kwargs
            ).status_code
            == 403
        )
    assert client.patch(f"/alamat/{second['id']}/jadikan-utama", headers=buyer).status_code == 200
    entries = client.get("/alamat", headers=buyer).json()
    assert sum(item["is_utama"] for item in entries) == 1
    assert entries[0]["id"] == second["id"]
    updated = client.put(
        f"/alamat/{a['id']}", headers=buyer, json=payload(alamat_lengkap="Jalan Baru 20")
    )
    assert updated.status_code == 200
    assert updated.json()["alamat_lengkap"] == "Jalan Baru 20"
    assert client.delete(f"/alamat/{second['id']}", headers=buyer).status_code == 204
    assert client.get("/alamat", headers=buyer).json()[0]["is_utama"] is True
    assert client.delete(f"/alamat/{uuid4()}", headers=buyer).status_code == 404


@pytest.mark.parametrize(
    "extra",
    [
        {"label": " "},
        {"nama_penerima": ""},
        {"no_hp": "abc"},
        {"no_hp": "abc081234567890xyz"},
        {"alamat_lengkap": " "},
        {"latitude": 91, "longitude": 0},
        {"latitude": 1},
        {"longitude": -181},
        {"is_utama": "yes"},
    ],
)
def test_address_invalid_input_is_specific_indonesian(addresses, extra):
    client, (buyer, _, _) = addresses
    result = client.post("/alamat", headers=buyer, json=payload(**extra))
    assert result.status_code == 422
    assert "message" in result.json()["detail"][0]
    assert client.get("/alamat", headers=buyer).json() == []

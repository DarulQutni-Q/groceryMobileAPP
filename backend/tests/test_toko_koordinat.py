"""Koordinat toko: seller menyimpan lewat PUT /toko/me, katalog publik
mengembalikannya supaya picker customer bisa menghitung jarak nyata."""

import pytest


@pytest.fixture
def seller_auth(client, account):
    response = client.post("/auth/register", json=account)
    assert response.status_code == 200
    return client, {"Authorization": "Bearer " + response.json()["access_token"]}


def test_koordinat_tersimpan_dan_tampil_di_katalog(seller_auth):
    http, seller = seller_auth
    updated = http.put(
        "/toko/me",
        headers=seller,
        json={
            "nama": "Toko Uji",
            "alamat": "Jalan Melati 1",
            "telepon": "081234567890",
            "latitude": 5.2443,
            "longitude": 97.0248,
        },
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["latitude"] == 5.2443
    assert updated.json()["longitude"] == 97.0248
    assert (
        http.patch("/toko/me/status", headers=seller, json={"status": "buka"}).status_code
        == 200
    )
    public = http.get("/toko", headers=seller)
    assert public.status_code == 200
    rows = public.json() if isinstance(public.json(), list) else public.json()["data"]
    mine = [t for t in rows if t["nama"] == "Toko Uji"]
    assert len(mine) == 1
    assert mine[0]["latitude"] == 5.2443
    assert mine[0]["longitude"] == 97.0248


def test_koordinat_di_luar_rentang_ditolak(seller_auth):
    http, seller = seller_auth
    bad = http.put(
        "/toko/me",
        headers=seller,
        json={"nama": "Toko Uji", "latitude": 100, "longitude": 0},
    )
    assert bad.status_code == 422

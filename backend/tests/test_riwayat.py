"""Riwayat status: baris 'baru' saat checkout, satu baris tiap transisi,
dan hanya pemilik pesanan / pemilik toko yang boleh membaca."""

import pytest
from uuid import uuid4


@pytest.fixture
def dunia(client, account):
    http = client
    users = []
    for payload in [
        account,
        {"role": "customer", "email": "buy@example.com", "password": "SandiUji123!"},
        {"role": "customer", "email": "other@example.com", "password": "SandiUji123!"},
    ]:
        response = http.post("/auth/register", json=payload)
        assert response.status_code == 200
        users.append({"Authorization": "Bearer " + response.json()["access_token"]})
    seller, buyer, other = users
    http.patch("/toko/me/status", headers=seller, json={"status": "buka"})
    product = http.post(
        "/produk",
        headers=seller,
        json={"nama": "Biskuit", "harga": 20000, "stok": 10, "satuan": "pcs", "kategori": "Camilan"},
    ).json()
    address = http.post(
        "/alamat",
        headers=buyer,
        json={
            "label": "Rumah",
            "nama_penerima": "Pembeli",
            "no_hp": "081234567890",
            "alamat_lengkap": "Jalan Melati 1",
        },
    ).json()
    body = {
        "alamat_id": address["id"],
        "metode_kirim": "Instant",
        "metode_bayar": "cod",
        "items": [{"produk_id": product["id"], "qty": 1}],
    }
    preview = http.post("/checkout/preview", headers=buyer, json=body)
    assert preview.status_code == 200
    order = http.post(
        "/checkout",
        headers={**buyer, "Idempotency-Key": "1720000000000-" + uuid4().hex},
        json={**body, "total_dikonfirmasi": preview.json()["total"]},
    )
    assert order.status_code == 201, order.text
    return http, seller, buyer, other, order.json()["pesanan"]["id"]


def test_riwayat_tertulis_per_transisi(dunia):
    http, seller, buyer, other, order_id = dunia
    rows = http.get(f"/pesanan/{order_id}/riwayat", headers=buyer).json()
    assert [r["status"] for r in rows] == ["baru"]
    assert http.patch(f"/pesanan/{order_id}/terima", headers=seller).status_code == 200
    assert http.patch(
        f"/pesanan/{order_id}/status", headers=seller, json={"status": "dikemas"}
    ).status_code == 200
    rows = http.get(f"/pesanan/{order_id}/riwayat", headers=buyer).json()
    assert [r["status"] for r in rows] == ["baru", "diproses", "dikemas"]
    toko_rows = http.get(f"/pesanan/toko/{order_id}/riwayat", headers=seller).json()
    assert [r["status"] for r in toko_rows] == ["baru", "diproses", "dikemas"]
    assert http.get(f"/pesanan/{order_id}/riwayat", headers=other).status_code == 404

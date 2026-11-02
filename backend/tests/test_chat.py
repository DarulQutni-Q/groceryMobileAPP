import pytest
"""Chat per pesanan: pelanggan dan toko saling berkirim, akses dibatasi
pemilik pesanan dan pemilik toko, pesan baru menulis notifikasi lawan."""

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


def test_chat_bolok_balik_dan_notifikasi(dunia):
    http, seller, buyer, other, order_id = dunia
    assert http.get(f"/chat/pesanan/{order_id}", headers=buyer).json() == []
    sent = http.post(
        f"/chat/pesanan/{order_id}", headers=buyer, json={"isi": "Kak, pesanan saya kapan diantar?"}
    )
    assert sent.status_code == 201, sent.text
    assert sent.json()["pengirim_peran"] == "customer"
    toko_list = http.get(f"/chat/toko/pesanan/{order_id}", headers=seller).json()
    assert len(toko_list) == 1
    assert toko_list[0]["isi"] == "Kak, pesanan saya kapan diantar?"
    reply = http.post(
        f"/chat/toko/pesanan/{order_id}",
        headers=seller,
        json={"isi": "Siang ini ya, Kak."},
    )
    assert reply.status_code == 201
    assert reply.json()["pengirim_peran"] == "toko"
    both = http.get(f"/chat/pesanan/{order_id}", headers=buyer).json()
    assert [m["isi"] for m in both] == [
        "Kak, pesanan saya kapan diantar?",
        "Siang ini ya, Kak.",
    ]
    # Notifikasi lawan bicara tercatat di kedua arah.
    seller_notes = http.get("/notifikasi", headers=seller).json()
    assert any("Pesan baru" in n["judul"] for n in seller_notes["data"])
    buyer_notes = http.get("/notifikasi", headers=buyer).json()
    assert any("Pesan baru" in n["judul"] for n in buyer_notes["data"])


def test_chat_dibatasi_pemilik(dunia):
    http, seller, buyer, other, order_id = dunia
    assert http.get(f"/chat/pesanan/{order_id}", headers=other).status_code == 404
    assert (
        http.post(f"/chat/pesanan/{order_id}", headers=other, json={"isi": "x"}).status_code
        == 404
    )
    assert http.post(
        f"/chat/pesanan/{order_id}", headers=buyer, json={"isi": ""}
    ).status_code == 422

import argparse
import secrets
import uuid

from smoke_auth import request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    args = parser.parse_args()
    base = args.base_url.rstrip("/")
    account = {"nama_pemilik": "Pemilik Uji A3", "nama_toko": "Toko Uji A3",
               "email": f"a3-{uuid.uuid4().hex}@example.com",
               "password": secrets.token_urlsafe(10) + "A1!"}
    token = request(base, "POST", "/auth/register", 200, account)["access_token"]
    produk = request(base, "POST", "/produk", 200,
                     {"nama": "Beras Uji A3", "harga": 15000, "stok": 20,
                      "satuan": "kg", "kategori": "Beras"}, token)
    data = {"items": [{"produk_id": produk["id"], "qty": 2}], "ongkir": 5000,
            "diskon": 1000, "biaya_layanan": 500, "alamat_kirim": "Jalan Pengujian 3"}
    orders = [request(base, "POST", "/pesanan/internal/test", 200, data, token) for _ in range(3)]
    assert len({order["kode"] for order in orders}) == 3
    assert all(order["total"] == 34500 for order in orders)
    request(base, "GET", "/pesanan", 401)
    listed = request(base, "GET", "/pesanan?status=baru", 200, token=token)
    assert len(listed) == 3 and all(order["status"] == "baru" for order in listed)
    paths = ["/pesanan/" + order["id"] for order in orders]
    request(base, "GET", paths[0], 200, token=token)
    assert request(base, "PATCH", paths[0] + "/terima", 200, token=token)["status"] == "diproses"
    assert request(base, "PATCH", paths[0] + "/urungkan", 200, token=token)["status"] == "baru"
    request(base, "PATCH", paths[0] + "/terima", 200, token=token)
    for status in ("dikemas", "diantar", "selesai"):
        changed = request(base, "PATCH", paths[0] + "/status", 200, {"status": status}, token)
        assert changed["status"] == status
    request(base, "PATCH", paths[1] + "/tolak", 422, {}, token)
    request(base, "PATCH", paths[1] + "/tolak", 422, {"alasan": " "}, token)
    rejected = request(base, "PATCH", paths[1] + "/tolak", 200, {"alasan": "Stok Habis"}, token)
    assert rejected["status"] == "ditolak" and rejected["tolak_alasan"] == "Stok Habis"
    request(base, "PATCH", paths[2] + "/status", 400, {"status": "selesai"}, token)
    request(base, "PATCH", paths[2] + "/status", 400, {"status": "ditolak"}, token)
    final = request(base, "GET", "/pesanan?status=selesai", 200, token=token)
    assert {order["status"] for order in final} == {"selesai", "ditolak"}
    assert len(request(base, "GET", "/pesanan?status=baru", 200, token=token)) == 1
    account["email"] = f"other-a3-{uuid.uuid4().hex}@example.com"
    other = request(base, "POST", "/auth/register", 200, account)["access_token"]
    request(base, "GET", paths[0], 404, token=other)
    request(base, "PATCH", paths[2] + "/terima", 404, token=other)
    request(base, "DELETE", "/produk/" + produk["id"], 200, token=token)
    detail = request(base, "GET", paths[0], 200, token=token)
    assert detail["items"][0]["produk_id"] is None
    assert detail["items"][0]["nama_snapshot"] == "Beras Uji A3"
    assert detail["items"][0]["harga_snapshot"] == 15000
    print("PASS A3 acceptance curl: tiga pesanan, filter, timeline, alasan, undo, ownership, snapshot.")


if __name__ == "__main__":
    main()

import io

from PIL import Image


def setup_product(client, account):
    tokens = client.post("/auth/register", json=account).json()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    produk = client.post(
        "/produk",
        headers=headers,
        json={"nama": "Beras", "harga": 15000, "stok": 5, "satuan": "kg", "kategori": "Beras"},
    ).json()
    return headers, f"/produk/{produk['id']}"


def photo(format="PNG"):
    data = io.BytesIO()
    Image.new("RGB", (16, 16), "green").save(data, format=format)
    return data.getvalue()


def test_upload_validates_content_size_and_serves_only_generated_files(client, account):
    headers, path = setup_product(client, account)
    for ext, mime, data in [
        ("png", "image/png", photo()),
        ("jpg", "image/jpeg", photo("JPEG")),
        ("webp", "image/webp", photo("WEBP")),
    ]:
        result = client.post(
            path + "/foto", headers=headers, files={"file": (f"../../unsafe.{ext}", data, mime)}
        )
        assert result.status_code == 200
        url = result.json()["foto_url"]
        assert url.startswith("/uploads/") and "unsafe" not in url
        response = client.get(url)
        assert response.status_code == 200
        assert response.content == data
    for filename, data, mime in [
        ("bad.png", b"not an image", "image/png"),
        ("bad.svg", b"<svg/>", "image/svg+xml"),
        ("bad.jpg", photo("JPEG")[:-20], "image/jpeg"),
        ("big.png", photo() + b"0" * (5 * 1024 * 1024), "image/png"),
    ]:
        result = client.post(
            path + "/foto", headers=headers, files={"file": (filename, data, mime)}
        )
        assert result.status_code == 422
    assert client.get("/uploads/not-a-photo.txt").status_code == 404
    url = client.get(path, headers=headers).json()["foto_url"]
    assert client.delete(path, headers=headers).status_code == 200
    assert client.get(url).status_code == 404

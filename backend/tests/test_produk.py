def test_product_create_validates_and_belongs_to_current_store(client, account):
    session = client.post("/auth/register", json=account).json()
    headers = {"Authorization": f"Bearer {session['access_token']}"}
    data = {"nama": "Beras Uji", "harga": 15000, "stok": 4, "satuan": "kg", "kategori": "Beras"}
    response = client.post("/produk", headers=headers, json=data)
    assert response.status_code == 200
    assert response.json()["is_tersedia"] is True
    assert response.json()["toko_id"] == client.get("/toko/me", headers=headers).json()["id"]
    for field, value, message in [
        ("harga", 0, "Harga"),
        ("stok", -1, "Stok"),
        ("satuan", "gram", "Satuan"),
    ]:
        invalid = dict(data, **{field: value})
        result = client.post("/produk", headers=headers, json=invalid)
        assert result.status_code == 422
        assert message in result.text


def test_product_crud_search_toggle_and_cross_seller_access(client, account):
    session = client.post("/auth/register", json=account).json()
    headers = {"Authorization": f"Bearer {session['access_token']}"}
    data = {"nama": "Beras Uji", "harga": 15000, "stok": 4, "satuan": "kg", "kategori": "Beras"}
    produk = client.post("/produk", headers=headers, json=data).json()
    path = f"/produk/{produk['id']}"
    result = client.get("/produk", headers=headers, params={"q": "beras", "kategori": "Beras"})
    assert result.status_code == 200
    assert [p["id"] for p in result.json()] == [produk["id"]]
    assert client.get("/produk?q=absent", headers=headers).json() == []
    assert client.get(path, headers=headers).json()["nama"] == "Beras Uji"
    assert client.put(path, headers=headers, json={"stok": 0}).json()["stok"] == 0
    assert client.put(path, headers=headers, json={"stok": None}).status_code == 422
    assert client.patch(path + "/toggle", headers=headers).json()["is_tersedia"] is False
    assert client.patch(path + "/toggle", headers=headers).json()["is_tersedia"] is True
    account["email"] = "other@example.com"
    other_session = client.post("/auth/register", json=account).json()
    other = {"Authorization": f"Bearer {other_session['access_token']}"}
    assert client.get("/produk", headers=other).json() == []
    for method, suffix, payload in [
        ("GET", "", None),
        ("PUT", "", {"stok": 9}),
        ("DELETE", "", None),
        ("PATCH", "/toggle", None),
    ]:
        assert client.request(method, path + suffix, headers=other, json=payload).status_code == 404
    assert client.delete(path, headers=headers).status_code == 200
    assert client.get(path, headers=headers).status_code == 404

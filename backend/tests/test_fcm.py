"""Tes pengirim FCM: konfigurasi, payload, best-effort, dan wiring router."""

import uuid
from types import SimpleNamespace

import pytest


class FakeResp:
    def __init__(self, status_code, text=""):
        self.status_code = status_code
        self.text = text


class FakeSession:
    calls = []

    def __init__(self, creds):
        self.creds = creds

    def post(self, url, json=None, timeout=None):
        FakeSession.calls.append({"url": url, "json": json})
        return FakeSession.response


class FakeCreds:
    project_id = "proyek-uji"


def _settings(path=""):
    from app.core.config import Settings

    return Settings(database_url="sqlite://", fcm_service_account_file=path)


def _patch_auth(monkeypatch, status=200):
    from app.services import fcm as fcm_mod

    monkeypatch.setattr(
        fcm_mod.service_account.Credentials,
        "from_service_account_file",
        classmethod(lambda cls, path, scopes=None: FakeCreds()),
    )
    monkeypatch.setattr(fcm_mod, "AuthorizedSession", FakeSession)
    FakeSession.calls = []
    FakeSession.response = FakeResp(status, "ok" if status == 200 else "bad")


def test_send_push_tanpa_konfigurasi_raise():
    from app.services.fcm import FcmNotConfigured, send_push

    with pytest.raises(FcmNotConfigured):
        send_push("tok", "Judul", "Isi", _settings(""))


def test_send_push_payload_dan_url_benar(monkeypatch):
    from app.services.fcm import send_push

    _patch_auth(monkeypatch, 200)
    send_push("tok123", "Pesanan DG-00001", "Status kini: Diproses", _settings("/tmp/sa.json"))
    assert len(FakeSession.calls) == 1
    call = FakeSession.calls[0]
    assert call["url"] == (
        "https://fcm.googleapis.com/v1/projects/proyek-uji/messages:send"
    )
    msg = call["json"]["message"]
    assert msg["fid"] == "tok123"
    assert msg["notification"] == {
        "title": "Pesanan DG-00001",
        "body": "Status kini: Diproses",
    }


def test_send_push_fcm_menolak_raise(monkeypatch):
    from app.services.fcm import FcmError, send_push

    _patch_auth(monkeypatch, 400)
    with pytest.raises(FcmError):
        send_push("tok", "J", "I", _settings("/tmp/sa.json"))


class FakeDb:
    def __init__(self, user):
        self.user = user

    def scalar(self, query):
        return self.user


def _pesanan(customer_id, kode="DG-00001", status="diproses"):
    return SimpleNamespace(
        id=uuid.uuid4(), customer_id=customer_id, kode=kode, status=status
    )


def test_notify_tanpa_customer_false_tanpa_http(monkeypatch):
    from app.services.fcm import notify_order_customer

    _patch_auth(monkeypatch, 200)
    assert notify_order_customer(FakeDb(None), _pesanan(None), _settings("/tmp/sa.json")) is False
    assert FakeSession.calls == []


def test_notify_tanpa_token_false(monkeypatch):
    from app.services.fcm import notify_order_customer

    _patch_auth(monkeypatch, 200)
    user = SimpleNamespace(fcm_token=None)
    assert notify_order_customer(FakeDb(user), _pesanan(uuid.uuid4()), _settings("/tmp/sa.json")) is False
    assert FakeSession.calls == []


def test_notify_dengan_token_true_dan_label_benar(monkeypatch):
    from app.services.fcm import notify_order_customer

    _patch_auth(monkeypatch, 200)
    user = SimpleNamespace(fcm_token="tok-cust")
    pesanan = _pesanan(uuid.uuid4(), kode="DG-00042", status="diantar")
    assert notify_order_customer(FakeDb(user), pesanan, _settings("/tmp/sa.json")) is True
    msg = FakeSession.calls[0]["json"]["message"]
    assert msg["fid"] == "tok-cust"
    assert msg["notification"]["title"] == "Pesanan DG-00042"
    assert "Diantar" in msg["notification"]["body"]
    assert msg["data"]["status"] == "diantar"


def test_notify_fcm_gagal_tetap_false_bukan_raise(monkeypatch):
    from app.services.fcm import notify_order_customer

    _patch_auth(monkeypatch, 500)
    user = SimpleNamespace(fcm_token="tok-cust")
    assert notify_order_customer(FakeDb(user), _pesanan(uuid.uuid4()), _settings("/tmp/sa.json")) is False


def test_router_terima_memanggil_notify(dev_client, monkeypatch, account):
    """Wiring: endpoint terima harus memanggil notify dengan hasil transisi."""
    from app.routers import pesanan as pesanan_router

    calls = []
    monkeypatch.setattr(
        pesanan_router,
        "notify_order_customer",
        lambda db, pesanan, settings: calls.append(pesanan.status) or True,
    )
    client = dev_client
    headers = _seller(client, account)
    produk = _product(client, headers)
    pesanan = _order(client, headers, produk["id"])
    r = client.patch(f"/pesanan/{pesanan['id']}/terima", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "diproses"
    assert calls == ["diproses"]


def _seller(client, account):
    response = client.post("/auth/register", json=account)
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _product(client, headers):
    response = client.post(
        "/produk",
        headers=headers,
        json={"nama": "Beras Uji", "harga": 15000, "stok": 20, "satuan": "kg", "kategori": "Beras"},
    )
    assert response.status_code == 200
    return response.json()


def _order(client, headers, produk_id):
    response = client.post(
        "/pesanan/internal/test",
        headers=headers,
        json={
            "items": [{"produk_id": produk_id, "qty": 2}],
            "ongkir": 5000,
            "diskon": 1000,
            "biaya_layanan": 500,
            "alamat_kirim": "Jalan Pengujian 3",
            "metode_kirim": "Instant",
            "slot_waktu": "Hari ini 15.00-17.00",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


@pytest.fixture
def dev_client(monkeypatch, request):
    monkeypatch.setenv("ENV", "dev")
    return request.getfixturevalue("client")

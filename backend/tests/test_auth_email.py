"""Tes pengiriman OTP lewat email: jujur saat SMTP belum siap atau gagal."""

import smtplib

SELLER = {
    "nama_pemilik": "Pemilik Tes",
    "nama_toko": "Toko Tes",
    "email": "email@example.com",
    "password": "Sandinya1!",
}


def _register(client):
    r = client.post("/auth/register", json=SELLER)
    assert r.status_code == 200, r.text


def test_forgot_password_tanpa_smtp_503(client):
    """Tanpa SMTP_USER/SMTP_PASSWORD, endpoint tidak boleh mengklaim terkirim."""
    _register(client)
    r = client.post("/auth/forgot-password", json={"email": SELLER["email"]})
    assert r.status_code == 503
    assert "belum dikonfigurasi" in r.json()["detail"]


def test_forgot_password_smtp_gagal_503_dan_otp_tidak_tersimpan(client, monkeypatch):
    """Gagal kirim = 503 dan tidak ada OTP yang tersimpan untuk ditebak."""

    def _gagal(email, code, settings=None):
        raise smtplib.SMTPException("koneksi ditolak")

    monkeypatch.setattr("app.services.auth.send_otp_email", _gagal)
    _register(client)
    r = client.post("/auth/forgot-password", json={"email": SELLER["email"]})
    assert r.status_code == 503
    assert "Gagal mengirim" in r.json()["detail"]
    r2 = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "123456"})
    assert r2.status_code == 400


def test_forgot_password_smtp_sukses_200_dan_otp_bisa_diverifikasi(client, monkeypatch):
    """Terkirim = 200, OTP tersimpan, dan bisa diverifikasi sampai reset token."""
    terkirim = {}

    def _rekam(email, code, settings=None):
        terkirim["email"] = email
        terkirim["code"] = code

    monkeypatch.setattr("app.services.auth.send_otp_email", _rekam)
    _register(client)
    r = client.post("/auth/forgot-password", json={"email": SELLER["email"]})
    assert r.status_code == 200
    assert r.json()["message"] == "Kode verifikasi telah dikirim"
    assert terkirim["email"] == SELLER["email"]
    r2 = client.post(
        "/auth/verify-otp",
        json={"email": SELLER["email"], "otp": terkirim["code"]},
    )
    assert r2.status_code == 200
    assert len(r2.json()["reset_token"]) > 10


def test_send_otp_email_isi_dan_login_smtp(monkeypatch):
    """Pesan email memuat kode, tujuan benar, dan login SMTP dipanggil."""
    from app.core.config import Settings
    from app.services import email as email_mod

    calls = {}

    class FakeSMTP:
        def __init__(self, host, port, timeout=None):
            calls["host"] = host
            calls["port"] = port
            calls["timeout"] = timeout

        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

        def starttls(self):
            calls["tls"] = True

        def login(self, user, password):
            calls["user"] = user
            calls["password"] = password

        def send_message(self, msg):
            calls["to"] = msg["To"]
            calls["subject"] = msg["Subject"]
            calls["body"] = msg.get_content()

    monkeypatch.setattr(smtplib, "SMTP", FakeSMTP)
    cfg = Settings(
        database_url="sqlite://",
        smtp_host="smtp.example.com",
        smtp_port=587,
        smtp_user="pengirim@example.com",
        smtp_password="rahasia",
        smtp_from="Toko <pengirim@example.com>",
    )
    email_mod.send_otp_email("tujuan@example.com", "445566", settings=cfg)
    assert calls["host"] == "smtp.example.com"
    assert calls["port"] == 587
    assert calls["tls"] is True
    assert calls["user"] == "pengirim@example.com"
    assert calls["password"] == "rahasia"
    assert calls["to"] == "tujuan@example.com"
    assert "445566" in calls["body"]
    assert "5 menit" in calls["body"]


def test_send_otp_email_tanpa_konfigurasi_raise():
    """Tanpa user/password, pengirim menolak sebelum menyentuh jaringan."""
    from app.core.config import Settings
    from app.services import email as email_mod

    cfg = Settings(database_url="sqlite://", smtp_user="", smtp_password="")
    try:
        email_mod.send_otp_email("tujuan@example.com", "445566", settings=cfg)
    except email_mod.EmailNotConfigured:
        return
    raise AssertionError("seharusnya EmailNotConfigured")

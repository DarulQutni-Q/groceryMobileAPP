"""Tes alur lupa sandi, verifikasi OTP, dan reset kata sandi."""

from datetime import timedelta, timezone

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SELLER = {
    "nama_pemilik": "Pemilik Tes",
    "nama_toko": "Toko Tes",
    "email": "reset@example.com",
    "password": "Sandinya1!",
}


def _register(client, data=None):
    payload = data or SELLER
    r = client.post("/auth/register", json=payload)
    assert r.status_code == 200, r.text
    return r.json()


def _forgot(client, email=SELLER["email"]):
    return client.post("/auth/forgot-password", json={"email": email})


def _get_otp(client, email=SELLER["email"]):
    """Ambil kode OTP langsung dari DB lewat endpoint debug tes."""
    # Panggil forgot-password lalu ambil OTP dari DB via internal query.
    # Karena kita tidak punya akses langsung ke DB di sini,
    # kita pakai monkeypatch di fixtures terpisah.
    r = _forgot(client, email)
    assert r.status_code == 200
    return r


# ---------------------------------------------------------------------------
# POST /auth/forgot-password
# ---------------------------------------------------------------------------


def test_forgot_password_email_tidak_terdaftar_404(client):
    r = client.post("/auth/forgot-password", json={"email": "tidakada@example.com"})
    assert r.status_code == 404
    assert "belum terdaftar" in r.json()["detail"]


def test_forgot_password_email_terdaftar_200(client):
    _register(client)
    r = _forgot(client)
    assert r.status_code == 200
    body = r.json()
    assert body["message"] == "Kode verifikasi telah dikirim"
    assert body["email"] == SELLER["email"]
    assert body["expires_in"] == 300
    assert "masked_phone" in body


def test_forgot_password_user_tanpa_phone_masked_phone_null(client):
    _register(client)
    r = _forgot(client)
    assert r.status_code == 200
    assert r.json()["masked_phone"] is None


def test_forgot_password_user_dengan_phone_masked_phone_tidak_null(client):
    customer = {
        "role": "customer",
        "email": "cust@example.com",
        "password": "Sandinya1!",
        "phone": "081234561234",
    }
    client.post("/auth/register", json=customer)
    r = client.post("/auth/forgot-password", json={"email": "cust@example.com"})
    assert r.status_code == 200
    masked = r.json()["masked_phone"]
    assert masked is not None
    assert "****" in masked


# ---------------------------------------------------------------------------
# POST /auth/verify-otp
# ---------------------------------------------------------------------------


def test_verify_otp_kode_salah_400(client):
    _register(client)
    _forgot(client)
    r = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "000000"})
    assert r.status_code == 400
    assert "tidak valid" in r.json()["detail"]


def test_verify_otp_format_bukan_6digit_422(client):
    _register(client)
    for bad in ["12345", "1234567", "abcdef", ""]:
        r = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": bad})
        assert r.status_code == 422, f"otp={bad!r} seharusnya 422 tapi dapat {r.status_code}"


def test_verify_otp_sukses_kembalikan_reset_token(client, monkeypatch):
    monkeypatch.setattr("random.randint", lambda a, b: 123456)
    _register(client)
    _forgot(client)
    r = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "123456"})
    assert r.status_code == 200
    body = r.json()
    assert body["message"] == "Kode verifikasi valid"
    assert len(body["reset_token"]) > 10


def test_verify_otp_kedaluwarsa_400(client, monkeypatch):
    """OTP yang sudah lewat waktu harus ditolak."""
    _register(client)

    # Buat OTP dengan kode 111111, lalu cek bahwa kode yang belum dibuat = expired check
    monkeypatch.setattr("random.randint", lambda a, b: 111111)
    _forgot(client)

    # Patch waktu agar OTP tampak expired pada saat verify
    from datetime import datetime as real_datetime

    past_time = real_datetime.now(timezone.utc) - timedelta(minutes=10)

    class FakeDatetime:
        @staticmethod
        def now(tz=None):
            return past_time

    monkeypatch.setattr("app.services.auth.datetime", FakeDatetime)

    # Dengan "now" = 10 menit lalu, expires_at > fake_now masih True.
    # Pendekatan lebih andal: patch datetime saat REQUEST OTP dibuat
    # agar expires_at di masa lalu, lalu restore untuk VERIFY.

    monkeypatch.undo()

    # Strategi: buat OTP dengan expires_at di masa lalu
    past_creation = real_datetime.now(timezone.utc) - timedelta(minutes=10)


    class FakeDatetimeForCreate:
        @staticmethod
        def now(tz=None):
            return past_creation

    monkeypatch.setattr("random.randint", lambda a, b: 222222)
    monkeypatch.setattr("app.services.auth.datetime", FakeDatetimeForCreate)
    _forgot(client)  # OTP 222222 dengan expires_at 5 menit lalu

    monkeypatch.setattr("app.services.auth.datetime", real_datetime)

    # Verify OTP expired harus ditolak
    r = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "222222"})
    assert r.status_code == 400
    assert "kedaluwarsa" in r.json()["detail"]


# ---------------------------------------------------------------------------
# POST /auth/reset-password
# ---------------------------------------------------------------------------


def test_reset_password_sandi_lemah_422(client, monkeypatch):
    monkeypatch.setattr("random.randint", lambda a, b: 654321)
    _register(client)
    _forgot(client)
    r_otp = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "654321"})
    assert r_otp.status_code == 200
    reset_token = r_otp.json()["reset_token"]

    for weak in ["12345678", "abcdefgh", "Abc12345"]:
        r = client.post(
            "/auth/reset-password",
            json={"email": SELLER["email"], "reset_token": reset_token, "password": weak},
        )
        assert r.status_code == 422, f"password={weak!r} seharusnya 422"


def test_reset_password_token_invalid_400(client):
    _register(client)
    r = client.post(
        "/auth/reset-password",
        json={
            "email": SELLER["email"],
            "reset_token": "invalid.token.here",
            "password": "SandiBaru1!",
        },
    )
    assert r.status_code == 400


def test_reset_password_sukses_dan_bisa_login_dengan_sandi_baru(client, monkeypatch):
    monkeypatch.setattr("random.randint", lambda a, b: 112233)
    _register(client)
    _forgot(client)

    r_otp = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "112233"})
    assert r_otp.status_code == 200
    reset_token = r_otp.json()["reset_token"]

    sandi_baru = "SandiBaru9@"
    r_reset = client.post(
        "/auth/reset-password",
        json={"email": SELLER["email"], "reset_token": reset_token, "password": sandi_baru},
    )
    assert r_reset.status_code == 200
    assert r_reset.json()["message"] == "Kata sandi berhasil diperbarui"

    # Login dengan sandi lama harus gagal
    r_lama = client.post(
        "/auth/login", json={"email": SELLER["email"], "password": SELLER["password"]}
    )
    assert r_lama.status_code == 401

    # Login dengan sandi baru harus berhasil
    r_baru = client.post(
        "/auth/login", json={"email": SELLER["email"], "password": sandi_baru}
    )
    assert r_baru.status_code == 200
    assert "access_token" in r_baru.json()


def test_reset_password_token_email_beda_400(client, monkeypatch):
    """Token yang emailnya berbeda harus ditolak."""
    monkeypatch.setattr("random.randint", lambda a, b: 445566)

    # Daftar dua user
    _register(client)
    user2 = {**SELLER, "email": "lain@example.com", "nama_toko": "Toko Lain"}
    _register(client, user2)

    # Dapatkan OTP untuk user pertama
    _forgot(client, SELLER["email"])
    r_otp = client.post(
        "/auth/verify-otp", json={"email": SELLER["email"], "otp": "445566"}
    )
    assert r_otp.status_code == 200
    reset_token = r_otp.json()["reset_token"]

    # Coba reset dengan token user pertama tapi email user kedua
    r = client.post(
        "/auth/reset-password",
        json={"email": "lain@example.com", "reset_token": reset_token, "password": "SandiBaru9@"},
    )
    assert r.status_code == 400


def test_otp_tidak_bisa_dipakai_ulang_setelah_reset(client, monkeypatch):
    """OTP harus di-invalidate setelah reset berhasil."""
    monkeypatch.setattr("random.randint", lambda a, b: 778899)
    _register(client)
    _forgot(client)

    r_otp = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "778899"})
    assert r_otp.status_code == 200
    reset_token = r_otp.json()["reset_token"]

    # Reset pertama
    client.post(
        "/auth/reset-password",
        json={"email": SELLER["email"], "reset_token": reset_token, "password": "SandiBaru8#"},
    )

    # OTP lama sudah di-invalidate, coba verify lagi harus gagal
    r2 = client.post("/auth/verify-otp", json={"email": SELLER["email"], "otp": "778899"})
    assert r2.status_code == 400

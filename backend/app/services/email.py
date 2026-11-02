"""Pengiriman email transaksional via SMTP standar (tanpa dependensi baru).

Konfigurasi dibaca dari Settings: SMTP_HOST (kosong = smtp.gmail.com),
SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM (kosong = SMTP_USER).
Tanpa SMTP_USER/SMTP_PASSWORD, pengiriman dianggap belum dikonfigurasi
dan pemanggil harus menolak dengan jujur, bukan mengklaim email terkirim.
"""

import smtplib
from email.message import EmailMessage

from app.core.config import Settings


class EmailNotConfigured(Exception):
    """SMTP belum dikonfigurasi sehingga email tidak dapat dikirim."""


def send_otp_email(to_email: str, code: str, settings: Settings | None) -> None:
    """Kirim kode OTP reset kata sandi. Settings datang dari app state
    (dibuat sekali saat startup), bukan dibangun per request, supaya tidak
    bergantung pada env yang bisa berubah di tengah jalan. Raise
    EmailNotConfigured bila SMTP belum dikonfigurasi, dan biarkan
    smtplib/OSError naik apa adanya bila pengiriman gagal, supaya pemanggil
    bisa menjawab 503 jujur."""
    cfg = settings
    if cfg is None:
        raise EmailNotConfigured("Settings tidak tersedia")
    user = cfg.smtp_user
    password = cfg.smtp_password.get_secret_value()
    if not user or not password:
        raise EmailNotConfigured("SMTP_USER/SMTP_PASSWORD belum diisi")
    msg = EmailMessage()
    msg["Subject"] = "Kode verifikasi reset kata sandi"
    msg["From"] = cfg.smtp_from or user
    msg["To"] = to_email
    lines = [
        f"Kode verifikasi kamu: {code}",
        "",
        "Kode ini berlaku 5 menit. Jangan bagikan kode ini ke siapa pun.",
        "",
        "Jika kamu tidak meminta reset kata sandi, abaikan email ini.",
    ]
    msg.set_content(chr(10).join(lines))
    host = cfg.smtp_host or "smtp.gmail.com"
    with smtplib.SMTP(host, cfg.smtp_port, timeout=15) as smtp:
        smtp.starttls()
        smtp.login(user, password)
        smtp.send_message(msg)

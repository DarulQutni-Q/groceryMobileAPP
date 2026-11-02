"""Pengiriman push notification via Firebase Cloud Messaging (FCM v1).

Satu-satunya konfigurasi adalah path file service account Firebase, dari
env FCM_SERVICE_ACCOUNT_FILE. File itu dipasang sendiri oleh operator di
VPS, tidak pernah lewat chat dan tidak pernah di-commit. Tanpa file itu,
pengiriman dianggap belum dikonfigurasi dan pemanggil best-effort harus
melanjutkan tanpa push, bukan menggagalkan transaksi.

google-auth sudah ada di requirements, jadi tidak ada dependensi baru.
"""

import logging
from typing import Any

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.user import User

_log = logging.getLogger(__name__)

_SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]

STATUS_LABELS = {
    "baru": "Baru",
    "diproses": "Diproses",
    "dikemas": "Dikemas",
    "diantar": "Diantar",
    "selesai": "Selesai",
    "ditolak": "Ditolak",
    "dibatalkan": "Dibatalkan",
}


class FcmNotConfigured(Exception):
    """File service account FCM belum dikonfigurasi."""


class FcmError(Exception):
    """FCM menolak pengiriman."""


def send_push(
    token: str,
    title: str,
    body: str,
    settings: Settings,
    data: dict[str, str] | None = None,
) -> None:
    """Kirim satu push FCM v1. Raise FcmNotConfigured bila file service
    account belum diisi, FcmError bila FCM menjawab bukan 200."""
    path = settings.fcm_service_account_file
    if not path:
        raise FcmNotConfigured("FCM_SERVICE_ACCOUNT_FILE belum diisi")
    creds = service_account.Credentials.from_service_account_file(
        path, scopes=_SCOPES
    )
    session = AuthorizedSession(creds)
    url = (
        "https://fcm.googleapis.com/v1/projects/"
        f"{creds.project_id}/messages:send"
    )
    # FCM v1: field "token" sudah deprecated, diganti "fid". Nilai yang
    # disimpan di kolom user.fcm_token kini adalah Firebase Installation ID.
    payload = {
        "message": {
            "fid": token,
            "notification": {"title": title, "body": body},
            "data": data or {},
        }
    }
    resp = session.post(url, json=payload, timeout=15)
    if resp.status_code != 200:
        raise FcmError(f"FCM {resp.status_code}: {resp.text[:200]}")


def notify_order_owner(db: Session, pesanan: Any, toko: Any, settings: Settings) -> bool:
    """Kirim push pesanan baru ke pemilik toko. Best-effort seperti
    notify_order_customer: tidak pernah raise."""
    try:
        owner = db.scalar(select(User).where(User.id == toko.owner_id))
        if owner is None or not owner.fcm_token:
            return False
        total = f"Rp {pesanan.total:,}".replace(",", ".")
        send_push(
            owner.fcm_token,
            f"Pesanan baru {pesanan.kode}",
            f"Pesanan baru senilai {total}, status: Baru",
            settings,
            data={"pesanan_id": str(pesanan.id), "status": "baru"},
        )
        return True
    except Exception:
        _log.warning(
            "gagal kirim push pesanan baru %s", getattr(pesanan, "kode", "?"),
            exc_info=True,
        )
        return False


def notify_order_customer(db: Session, pesanan: Any, settings: Settings) -> bool:
    """Kirim push status pesanan ke customer. Best-effort: tidak pernah
    raise, supaya kegagalan push tidak menggagalkan perubahan status.
    Mengembalikan True bila push terkirim, False bila tidak (tanpa
    customer, tanpa token, belum dikonfigurasi, atau FCM gagal)."""
    try:
        if pesanan.customer_id is None:
            return False
        user = db.scalar(select(User).where(User.id == pesanan.customer_id))
        if user is None or not user.fcm_token:
            return False
        label = STATUS_LABELS.get(pesanan.status, pesanan.status)
        send_push(
            user.fcm_token,
            f"Pesanan {pesanan.kode}",
            f"Status pesananmu kini: {label}",
            settings,
            data={"pesanan_id": str(pesanan.id), "status": pesanan.status},
        )
        return True
    except Exception:
        _log.warning(
            "gagal kirim push pesanan %s", getattr(pesanan, "kode", "?"),
            exc_info=True,
        )
        return False

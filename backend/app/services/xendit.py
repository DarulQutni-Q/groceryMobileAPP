from urllib.parse import urlsplit

import requests
from fastapi import HTTPException, Request

CHANNELS = {
    "qris": "QRIS",
    "gopay": "GOPAY",
    "shopeepay": "SHOPEEPAY",
    "va_bca": "BCA",
    "va_bri": "BRI",
    "va_mandiri": "MANDIRI",
}


def safe_payment_url(value):
    if not isinstance(value, str) or len(value) > 2048:
        raise HTTPException(502, "Tautan pembayaran tidak valid")
    try:
        url = urlsplit(value)
        hostname = url.hostname
    except ValueError:
        raise HTTPException(502, "Tautan pembayaran tidak valid") from None
    if (
        url.scheme != "https"
        or not hostname
        or url.username
        or url.password
        or not (hostname == "xendit.co" or hostname.endswith(".xendit.co"))
    ):
        raise HTTPException(502, "Tautan pembayaran tidak valid")
    return value


class Xendit:
    def __init__(self, settings, metode):
        self.key = settings.xendit_api_key.get_secret_value()
        self.channel = CHANNELS.get(metode)

    def available(self):
        if not self.key.startswith("xnd_development"):
            raise HTTPException(503, "Pembayaran Xendit sandbox belum dikonfigurasi")

    def request(self, method, path, **kwargs):
        self.available()
        try:
            response = requests.request(
                method,
                "https://api.xendit.co" + path,
                auth=(self.key, ""),
                timeout=(5, 15),
                allow_redirects=False,
                **kwargs,
            )
            if not 200 <= response.status_code < 300:
                raise HTTPException(503, "Xendit belum dapat memproses pembayaran, coba lagi")
            return response.json()
        except (requests.RequestException, ValueError):
            raise HTTPException(
                503, "Status invoice belum pasti, periksa pembayaran sebelum mencoba lagi"
            ) from None

    def create_invoice(self, external_id, amount, payer_email, description):
        return self.request(
            "POST",
            "/v2/invoices",
            json={
                "external_id": external_id,
                "amount": amount,
                "payer_email": payer_email,
                "description": description,
                "currency": "IDR",
                "invoice_duration": 3600,
                "payment_methods": [self.channel],
            },
        )

    def find_invoice(self, external_id):
        values = self.request("GET", "/v2/invoices", params={"external_id": external_id})
        if not isinstance(values, list) or len(values) != 1:
            raise HTTPException(503, "Status invoice belum pasti, coba periksa lagi nanti")
        return values[0]

    def get_invoice(self, invoice_id):
        return self.request("GET", f"/v2/invoices/{invoice_id}")


def get_gateway(request: Request):
    return lambda metode: Xendit(request.app.state.settings, metode)

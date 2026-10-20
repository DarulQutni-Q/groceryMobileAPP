import json

from fastapi import HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

LABELS = {
    "nama": "Nama",
    "nama_pemilik": "Nama pemilik",
    "nama_toko": "Nama toko",
    "email": "Alamat email",
    "password": "Kata sandi",
    "phone": "Nomor telepon",
    "telepon": "Nomor telepon",
    "harga": "Harga",
    "stok": "Stok",
    "satuan": "Satuan",
    "kategori": "Kategori",
    "radius_km": "Radius pengiriman",
    "alamat": "Alamat",
    "deskripsi": "Deskripsi",
    "metode_kirim": "Metode kirim",
    "rekening_bank": "Rekening bank",
    "qty": "Jumlah barang",
    "alasan": "Alasan penolakan",
    "catatan": "Catatan",
    "limit": "Limit",
    "page": "Halaman",
    "per_page": "Jumlah per halaman",
    "fcm_token": "Token notifikasi",
    "id_token": "Token Google",
    "refresh_token": "Token refresh",
}


def message_for(error, path):
    field, kind = str(error["loc"][-1]), error["type"]
    label, context = LABELS.get(field, field.replace("_", " ").capitalize()), error.get("ctx", {})
    if field == "email":
        return "Alamat email tidak valid"
    if kind == "value_error":
        return str(error["msg"]).removeprefix("Value error, ")
    if kind == "json_invalid":
        return "JSON tidak valid"
    if kind == "missing":
        return f"{label} wajib diisi"
    if "uuid" in kind:
        return f"{label} harus berupa UUID yang valid"
    if kind == "literal_error":
        if field == "range":
            return "Rentang harus 7h atau 30h"
        if field == "satuan":
            return "Satuan harus kg, pcs, atau liter"
        if field == "status" and path.startswith("/toko"):
            return "Status harus buka atau tutup"
        choices = str(context.get("expected", "pilihan yang tersedia")).replace("'", "")
        return f"{label} harus {choices.replace(' or ', ' atau ')}"
    if field in {"phone", "telepon"} and kind == "string_pattern_mismatch":
        return "Nomor telepon harus berisi angka, boleh diawali +"
    templates = {
        "greater_than": ("harus lebih dari", "gt"),
        "greater_than_equal": ("minimal", "ge"),
        "less_than": ("harus kurang dari", "lt"),
        "less_than_equal": ("maksimal", "le"),
        "string_too_short": ("minimal", "min_length"),
        "string_too_long": ("maksimal", "max_length"),
        "too_short": ("minimal", "min_length"),
        "too_long": ("maksimal", "max_length"),
    }
    if kind in templates:
        wording, key = templates[kind]
        unit = " karakter" if kind.startswith("string_") else ""
        return f"{label} {wording} {context[key]}{unit}"
    if kind in {"int_type", "int_parsing", "int_from_float"}:
        return f"{label} harus berupa bilangan bulat"
    if kind in {"bool_type", "bool_parsing"}:
        return f"{label} harus true atau false"
    if kind == "extra_forbidden":
        return f"Kolom {field} tidak dikenal"
    return f"Isian {label} tidak valid"


async def validation_error(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "detail": [
                {
                    "field": "body" if error["type"] == "json_invalid" else str(error["loc"][-1]),
                    "message": message_for(error, request.url.path),
                }
                for error in exc.errors()
            ]
        },
    )


async def check_json_depth(request: Request):
    if request.method not in {"POST", "PUT", "PATCH", "DELETE"}:
        return
    content_type = request.headers.get("content-type", "").split(";", 1)[0].lower()
    if content_type != "application/json" and not content_type.endswith("+json"):
        return
    try:
        value = await request.json()
    except json.JSONDecodeError:
        return
    except (ValueError, RecursionError) as exc:
        raise HTTPException(400, "JSON tidak dapat dibaca atau terlalu besar") from exc
    pending = [(value, 0)]
    while pending:
        item, depth = pending.pop()
        if depth > 100:
            raise HTTPException(400, "JSON terlalu dalam, maksimal 100 tingkat")
        children = (
            item.values() if isinstance(item, dict) else item if isinstance(item, list) else ()
        )
        pending.extend((child, depth + 1) for child in children)

import io
import logging
import re
import warnings
from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError

MAX_BYTES = 5 * 1024 * 1024
FORMATS = {
    "JPEG": ("jpg", "image/jpeg"),
    "PNG": ("png", "image/png"),
    "WEBP": ("webp", "image/webp"),
}
FILE_PATTERN = re.compile(r"[a-f0-9]{32}\.(jpg|png|webp)\Z")


def read_photo(file: UploadFile) -> tuple[bytes, str]:
    try:
        data = file.file.read(MAX_BYTES + 1)
    finally:
        file.file.close()
    if len(data) > MAX_BYTES:
        raise HTTPException(422, "Foto maksimal 5 MB")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(data)) as image:
                ext, mime = FORMATS.get(image.format, (None, None))
                if (
                    ext is None
                    or mime != file.content_type
                    or image.width * image.height > 25000000
                ):
                    raise ValueError("Format atau dimensi foto tidak valid")
                if Path(file.filename or "").suffix.lower() not in {
                    ".jpg",
                    ".jpeg",
                    ".png",
                    ".webp",
                }:
                    raise ValueError("Ekstensi foto tidak valid")
                image.load()
    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombWarning,
        Image.DecompressionBombError,
    ) as exc:
        raise HTTPException(
            422, "Foto harus JPG, PNG, atau WebP yang valid (maksimal 25 MP)"
        ) from exc
    return data, ext


def save_photo(directory: Path, data: bytes, ext: str) -> str:
    name = f"{uuid4().hex}.{ext}"
    path = directory / name
    try:
        path.write_bytes(data)
    except OSError as exc:
        path.unlink(missing_ok=True)
        raise HTTPException(503, "Foto belum dapat disimpan. Coba lagi.") from exc
    return f"/uploads/{name}"


def remove_photo(directory: Path, url: str | None):
    if url and url.startswith("/uploads/") and FILE_PATTERN.fullmatch(url[9:]):
        try:
            (directory / url[9:]).unlink(missing_ok=True)
        except OSError:
            logging.getLogger("grocery.uploads").exception("Foto lama belum dapat dibersihkan")

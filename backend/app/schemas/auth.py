import re
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

from app.schemas.input import PHONE_PATTERN, InputModel


def customer_phone(value: str) -> str:
    digits = re.sub(r"[ ()-]", "", value).removeprefix("+")
    national = digits[2:] if digits.startswith("62") else digits.removeprefix("0")
    if not re.fullmatch(r"8[0-9]{8,11}", national):
        raise ValueError("Nomor handphone Indonesia harus berisi 9-12 angka setelah +62")
    return "+62" + national


class RegisterRequest(InputModel):
    role: Literal["seller", "customer"] = "seller"
    nama_pemilik: str | None = Field(default=None, min_length=1, max_length=120)
    nama_toko: str | None = Field(default=None, min_length=1, max_length=120)
    email: EmailStr = Field(max_length=254)
    password: str = Field(min_length=8, max_length=20)
    phone: str | None = Field(
        default=None, min_length=6, max_length=32, pattern=f"^{PHONE_PATTERN}$"
    )

    @field_validator("nama_pemilik", "nama_toko")
    @classmethod
    def required_name(cls, value):
        if value is None:
            return value
        if not value.strip():
            raise ValueError("Nama wajib diisi")
        return value.strip()

    @model_validator(mode="after")
    def seller_names(self):
        if self.role == "seller" and (not self.nama_pemilik or not self.nama_toko):
            raise ValueError("Nama pemilik dan nama toko wajib diisi untuk akun seller")
        return self

    @field_validator("phone")
    @classmethod
    def normalize_customer_phone(cls, value, info):
        return customer_phone(value) if value and info.data.get("role") == "customer" else value

    @field_validator("password")
    @classmethod
    def strong_password(cls, value):
        if not 8 <= len(value) <= 20:
            raise ValueError("Kata sandi harus terdiri dari 8-20 karakter")
        if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
            raise ValueError("Kata sandi wajib memuat huruf dan angka")
        if not any(not c.isalnum() and not c.isspace() for c in value):
            raise ValueError("Kata sandi wajib memuat karakter khusus")
        if len(value.encode()) > 72:
            raise ValueError("Kata sandi melebihi batas 72 byte, kurangi karakter multibyte")
        return value


class LoginRequest(InputModel):
    role: Literal["seller", "customer"] = "seller"
    email: EmailStr = Field(max_length=254)
    password: str = Field(min_length=1, max_length=256)


class PhoneLoginRequest(InputModel):
    phone: str = Field(min_length=6, max_length=32, pattern=f"^{PHONE_PATTERN}$")
    password: str = Field(min_length=1, max_length=256)

    @field_validator("phone")
    @classmethod
    def normalized_phone(cls, value):
        return customer_phone(value)


class GoogleLoginRequest(InputModel):
    role: Literal["seller", "customer"] = "seller"
    id_token: str = Field(min_length=1, max_length=8192, pattern=r"^\S+$")


class RefreshRequest(InputModel):
    refresh_token: str = Field(min_length=1, max_length=8192, pattern=r"^\S+$")


class FcmTokenRequest(InputModel):
    fcm_token: str = Field(min_length=1, max_length=4096, pattern=r"^\S+$")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    nama: str
    email: str
    phone: str | None
    role: str
    nama_toko: str | None


class ForgotPasswordRequest(InputModel):
    email: EmailStr = Field(max_length=254)


class VerifyOtpRequest(InputModel):
    email: EmailStr = Field(max_length=254)
    otp: str = Field(min_length=6, max_length=6, pattern=r"^[0-9]{6}$")


class ResetPasswordRequest(InputModel):
    email: EmailStr = Field(max_length=254)
    reset_token: str = Field(min_length=1, max_length=8192, pattern=r"^\S+$")
    password: str = Field(min_length=8, max_length=20)

    @field_validator("password")
    @classmethod
    def strong_password(cls, value):
        if not 8 <= len(value) <= 20:
            raise ValueError("Kata sandi harus terdiri dari 8-20 karakter")
        if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
            raise ValueError("Kata sandi wajib memuat huruf dan angka")
        if not any(not c.isalnum() and not c.isspace() for c in value):
            raise ValueError("Kata sandi wajib memuat karakter khusus")
        if len(value.encode()) > 72:
            raise ValueError("Kata sandi melebihi batas 72 byte, kurangi karakter multibyte")
        return value


class ForgotPasswordResponse(BaseModel):
    message: str
    email: str
    expires_in: int
    masked_phone: str | None


class VerifyOtpResponse(BaseModel):
    message: str
    reset_token: str


class ResetPasswordResponse(BaseModel):
    message: str

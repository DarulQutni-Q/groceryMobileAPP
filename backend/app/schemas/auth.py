from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class SellerRegisterRequest(BaseModel):
    nama_pemilik: str = Field(min_length=1, max_length=120)
    nama_toko: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str
    phone: str | None = Field(default=None, min_length=6, max_length=32)

    @field_validator("nama_pemilik", "nama_toko")
    @classmethod
    def required_name(cls, value):
        if not value.strip():
            raise ValueError("Nama wajib diisi")
        return value.strip()

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


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(max_length=256)


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=1, max_length=8192)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=1, max_length=8192)


class FcmTokenRequest(BaseModel):
    fcm_token: str = Field(min_length=1, max_length=4096)


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

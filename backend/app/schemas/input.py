from pydantic import BaseModel, field_validator


def safe_text(value):
    if isinstance(value, str) and "\x00" in value:
        raise ValueError("Teks tidak boleh memuat karakter NUL")
    if isinstance(value, list):
        for item in value:
            safe_text(item)
    elif isinstance(value, dict):
        for key, item in value.items():
            safe_text(key)
            safe_text(item)
    return value


PHONE_PATTERN = r"\+?[0-9][0-9 ()-]{4,30}[0-9]"


class InputModel(BaseModel):
    @field_validator("*", mode="before")
    @classmethod
    def safe_values(cls, value):
        return safe_text(value)

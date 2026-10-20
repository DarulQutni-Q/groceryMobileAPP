from pydantic import BaseModel, field_validator


def safe_text(value):
    pending = [value]
    while pending:
        item = pending.pop()
        if isinstance(item, str) and "\x00" in item:
            raise ValueError("Teks tidak boleh memuat karakter NUL")
        if isinstance(item, list):
            pending.extend(item)
        elif isinstance(item, dict):
            pending.extend(item.keys())
            pending.extend(item.values())
    return value


PHONE_PATTERN = r"\+?[0-9][0-9 ()-]{4,30}[0-9]"


class InputModel(BaseModel):
    @field_validator("*", mode="before")
    @classmethod
    def safe_values(cls, value):
        return safe_text(value)

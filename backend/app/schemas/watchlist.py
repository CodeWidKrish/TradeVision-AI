from datetime import datetime
from pydantic import BaseModel, field_validator

class WatchlistCreate(BaseModel):
    symbol: str

    @field_validator("symbol")
    @classmethod
    def validate_symbol(cls, v: str) -> str:
        if not v or not isinstance(v, str):
            raise ValueError("Symbol must be a non-empty string")
        cleaned = v.strip().upper()
        if not cleaned:
            raise ValueError("Symbol cannot be empty or whitespace only")
        return cleaned

class WatchlistResponse(BaseModel):
    id: int
    user_id: int
    symbol: str
    added_at: datetime

    class Config:
        from_attributes = True

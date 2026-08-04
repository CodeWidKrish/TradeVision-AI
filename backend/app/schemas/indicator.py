from pydantic import BaseModel
from typing import Optional

class IndicatorResponse(BaseModel):
    symbol: str
    rsi: Optional[float] = None
    ma20: Optional[float] = None
    ma50: Optional[float] = None
    macd: Optional[float] = None
    signal: str
    message: Optional[str] = None
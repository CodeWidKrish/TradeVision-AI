from pydantic import BaseModel
from typing import List, Optional

class IndicatorResponse(BaseModel):
    symbol: str
    rsi: Optional[float] = None
    ma20: Optional[float] = None
    ma50: Optional[float] = None
    ma200: Optional[float] = None
    macd: Optional[float] = None
    macd_signal: Optional[float] = None
    macd_histogram: Optional[float] = None
    bollinger_upper: Optional[float] = None
    bollinger_lower: Optional[float] = None
    signal: str = "hold"   # buy | sell | hold
    message: Optional[str] = None
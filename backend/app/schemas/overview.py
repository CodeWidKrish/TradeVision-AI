from pydantic import BaseModel
from typing import Optional

class StockInfo(BaseModel):
    symbol: str
    company_name: Optional[str] = None
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    status: str = "active"
    message: Optional[str] = None

class IndicatorInfo(BaseModel):
    symbol: str
    rsi: Optional[float] = None
    ma20: Optional[float] = None
    ma50: Optional[float] = None
    macd: Optional[float] = None
    signal: str
    message: Optional[str] = None

class OverviewResponse(BaseModel):
    stock: StockInfo
    indicators: IndicatorInfo
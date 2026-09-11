from pydantic import BaseModel
from typing import Optional

class StockDetailResponse(BaseModel):
    symbol: str
    company_name: Optional[str] = None
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    change_amount: Optional[float] = None
    open_price: Optional[float] = None
    high_price: Optional[float] = None
    low_price: Optional[float] = None
    prev_close: Optional[float] = None
    volume: Optional[int] = None
    avg_volume: Optional[int] = None
    market_cap: Optional[float] = None
    pe_ratio: Optional[float] = None
    eps: Optional[float] = None
    fifty_two_week_high: Optional[float] = None
    fifty_two_week_low: Optional[float] = None
    sector: Optional[str] = None
    industry: Optional[str] = None
    status: str = "active"
    message: Optional[str] = None
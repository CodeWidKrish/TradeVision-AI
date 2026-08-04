from pydantic import BaseModel
from typing import Optional

class StockDetailResponse(BaseModel):
    symbol: str
    company_name: Optional[str] = None
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    open_price: Optional[float] = None
    high_price: Optional[float] = None
    low_price: Optional[float] = None
    volume: Optional[int] = None
    status: str = "active"
    message: Optional[str] = None
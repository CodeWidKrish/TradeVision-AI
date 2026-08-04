from pydantic import BaseModel
from typing import Optional

class StockResponse(BaseModel):
    symbol: str
    company_name: Optional[str] = None
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    status: str = "active"
    message: Optional[str] = None
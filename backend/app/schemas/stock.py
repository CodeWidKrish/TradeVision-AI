from pydantic import BaseModel
from typing import Optional, List, Any

class StockResponse(BaseModel):
    symbol: str
    ticker: Optional[str] = None
    company_name: Optional[str] = None
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    change_amount: Optional[float] = None
    volume: Optional[int] = None
    market_cap: Optional[float] = None
    sector: Optional[str] = None
    cap_tier: Optional[str] = None
    website_domain: Optional[str] = None
    is_positive: Optional[bool] = None
    status: str = "active"
    message: Optional[str] = None

class StockSearchItem(BaseModel):
    symbol: str
    ticker: str
    company_name: str
    series: Optional[str] = "EQ"
    isin: Optional[str] = ""
    exchange: str = "NSE"
    sector: Optional[str] = "General Equity"
    cap_tier: Optional[str] = "Equity"
    website_domain: Optional[str] = ""
    current_price: Optional[float] = None
    change_percent: Optional[float] = None
    change_amount: Optional[float] = None
    is_positive: Optional[bool] = None

class StockSearchResponse(BaseModel):
    count: int
    query: str
    results: List[StockSearchItem]

class StockUniverseResponse(BaseModel):
    count: int
    total_equities: int = 2595
    offset: int
    limit: int
    sector: Optional[str] = None
    results: List[StockSearchItem]
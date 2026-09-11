from pydantic import BaseModel
from typing import List, Optional

class ChartPoint(BaseModel):
    date: str
    open: float
    high: float
    low: float
    close: float
    volume: Optional[int] = None

class ChartResponse(BaseModel):
    symbol: str
    period: str = "1mo"
    points: List[ChartPoint]
    message: Optional[str] = None
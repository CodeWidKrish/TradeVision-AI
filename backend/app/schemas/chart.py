from pydantic import BaseModel
from typing import List

class ChartPoint(BaseModel):
    date: str
    open: float
    high: float
    low: float
    close: float
    volume: int

class ChartResponse(BaseModel):
    symbol: str
    points: List[ChartPoint]
    message: str = "Chart data loaded"
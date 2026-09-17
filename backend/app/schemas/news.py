from pydantic import BaseModel
from typing import List, Optional

class NewsArticle(BaseModel):
    title: str
    summary: Optional[str] = None
    source: Optional[str] = None
    url: Optional[str] = None
    published_at: Optional[str] = None
    time_ago: Optional[str] = None
    related_ticker: Optional[str] = None
    sentiment: Optional[str] = "neutral"   # bullish | bearish | neutral
    category: Optional[str] = "Markets"    # Markets | Earnings | Economy | Tech

class NewsResponse(BaseModel):
    symbol: str
    articles: List[NewsArticle]
    message: Optional[str] = None
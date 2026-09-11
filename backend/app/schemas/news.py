from pydantic import BaseModel
from typing import List, Optional

class NewsArticle(BaseModel):
    title: str
    source: Optional[str] = None
    url: Optional[str] = None
    published_at: Optional[str] = None
    sentiment: Optional[str] = "neutral"   # bullish | bearish | neutral

class NewsResponse(BaseModel):
    symbol: str
    articles: List[NewsArticle]
    message: Optional[str] = None
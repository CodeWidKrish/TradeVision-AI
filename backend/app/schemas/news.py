from pydantic import BaseModel
from typing import List

class NewsItem(BaseModel):
    title: str
    source: str
    url: str
    published_at: str

class NewsResponse(BaseModel):
    symbol: str
    articles: List[NewsItem]
    message: str = "News loaded"
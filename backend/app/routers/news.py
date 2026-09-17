from fastapi import APIRouter, Query
from app.schemas.news import NewsResponse
from app.services.news_service import get_news_by_symbol, get_market_news

router = APIRouter(prefix="/news", tags=["news"])

@router.get("", response_model=NewsResponse)
@router.get("/market", response_model=NewsResponse)
def get_market_headlines(limit: int = Query(15, ge=1, le=50, description="Max articles to return")):
    """Fetch live Indian stock market, economy, and corporate earnings news."""
    return get_market_news(limit=limit)

@router.get("/{symbol}", response_model=NewsResponse)
def get_news(symbol: str, limit: int = Query(10, ge=1, le=30, description="Max articles to return")):
    """Fetch live news specifically for an equity ticker."""
    return get_news_by_symbol(symbol=symbol, limit=limit)
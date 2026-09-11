from fastapi import APIRouter
from app.schemas.news import NewsResponse
from app.services.news_service import get_news_by_symbol

router = APIRouter(prefix="/news", tags=["news"])

@router.get("/{symbol}", response_model=NewsResponse)
def get_news(symbol: str):
    return get_news_by_symbol(symbol)
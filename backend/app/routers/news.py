from fastapi import APIRouter, HTTPException
from app.schemas.news import NewsResponse
from app.services.news_service import get_news_by_symbol

router = APIRouter(prefix="/news", tags=["news"])

@router.get("/{symbol}", response_model=NewsResponse)
def get_news(symbol: str):
    result = get_news_by_symbol(symbol)

    if not result["articles"]:
        raise HTTPException(status_code=404, detail="News not found")

    return result
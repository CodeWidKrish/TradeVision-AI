from fastapi import APIRouter, Query
from app.schemas.indicator import IndicatorResponse
from app.services.indicator_service import get_indicator_by_symbol

router = APIRouter(prefix="/indicators", tags=["indicators"])

@router.get("", response_model=IndicatorResponse)
def get_indicators(symbol: str = Query(..., description="Stock ticker symbol")):
    return get_indicator_by_symbol(symbol)
from fastapi import APIRouter, HTTPException
from app.schemas.indicator import IndicatorResponse
from app.services.indicator_service import get_indicator_by_symbol

router = APIRouter(prefix="/indicators", tags=["indicators"])

@router.get("/", response_model=IndicatorResponse)
def get_indicators(symbol: str):
    result = get_indicator_by_symbol(symbol)

    if result["signal"] == "not_found":
        raise HTTPException(status_code=404, detail="Indicator data not found")

    return result
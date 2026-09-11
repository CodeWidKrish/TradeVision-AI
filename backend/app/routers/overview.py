from fastapi import APIRouter, Query
from app.schemas.overview import OverviewResponse
from app.services.overview_service import get_overview_by_symbol

router = APIRouter(prefix="/overview", tags=["overview"])

@router.get("", response_model=OverviewResponse)
def get_overview(symbol: str = Query(..., description="Stock ticker symbol")):
    return get_overview_by_symbol(symbol)
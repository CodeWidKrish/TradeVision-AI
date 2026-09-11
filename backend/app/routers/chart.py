from fastapi import APIRouter, Query
from app.schemas.chart import ChartResponse
from app.services.chart_service import get_chart_by_symbol

router = APIRouter(prefix="/chart", tags=["chart"])

@router.get("/{symbol}", response_model=ChartResponse)
def get_chart(symbol: str, period: str = Query("1m", description="1d|1w|1m|3m|6m|1y|all")):
    return get_chart_by_symbol(symbol, period)
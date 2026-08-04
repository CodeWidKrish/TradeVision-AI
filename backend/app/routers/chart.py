from fastapi import APIRouter, HTTPException
from app.schemas.chart import ChartResponse
from app.services.chart_service import get_chart_by_symbol

router = APIRouter(prefix="/chart", tags=["chart"])

@router.get("/{symbol}", response_model=ChartResponse)
def get_chart(symbol: str):
    result = get_chart_by_symbol(symbol)

    if not result["points"]:
        raise HTTPException(status_code=404, detail="Chart data not found")

    return result
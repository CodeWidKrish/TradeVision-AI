from fastapi import APIRouter, HTTPException
from app.schemas.overview import OverviewResponse
from app.services.overview_service import get_overview_by_symbol

router = APIRouter(prefix="/overview", tags=["overview"])

@router.get("/", response_model=OverviewResponse)
def get_overview(symbol: str):
    result = get_overview_by_symbol(symbol)

    if result is None:
        raise HTTPException(status_code=404, detail="Overview data not found")

    return result
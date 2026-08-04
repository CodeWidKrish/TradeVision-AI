from fastapi import APIRouter, HTTPException
from app.schemas.stock_detail import StockDetailResponse
from app.services.stock_detail_service import get_stock_detail_by_symbol

router = APIRouter(prefix="/stock-details", tags=["stock-details"])

@router.get("/{symbol}", response_model=StockDetailResponse)
def get_stock_details(symbol: str):
    result = get_stock_detail_by_symbol(symbol)

    if result["status"] == "not_found":
        raise HTTPException(status_code=404, detail="Stock detail not found")

    return result
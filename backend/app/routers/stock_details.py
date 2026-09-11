from fastapi import APIRouter
from app.schemas.stock_detail import StockDetailResponse
from app.services.stock_detail_service import get_stock_detail_by_symbol

router = APIRouter(prefix="/stock-details", tags=["stock-details"])

@router.get("/{symbol}", response_model=StockDetailResponse)
def get_stock_detail(symbol: str):
    return get_stock_detail_by_symbol(symbol)
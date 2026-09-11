from fastapi import APIRouter
from app.schemas.stock import StockResponse
from app.services.stock_service import get_stock_by_symbol

router = APIRouter(prefix="/stocks", tags=["stocks"])

@router.get("/{symbol}", response_model=StockResponse)
def get_stock(symbol: str):
    return get_stock_by_symbol(symbol)
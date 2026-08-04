from fastapi import APIRouter, HTTPException
from app.schemas.stock import StockResponse
from app.services.stock_service import get_stock_by_symbol

router = APIRouter(prefix="/stocks", tags=["stocks"])

@router.get("/{symbol}", response_model=StockResponse)
def read_stock(symbol: str):
    result = get_stock_by_symbol(symbol)

    if result["status"] == "not_found":
        raise HTTPException(status_code=404, detail="Stock not found")

    return result
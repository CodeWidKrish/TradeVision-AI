from fastapi import APIRouter, Query
from typing import Optional, List, Dict, Any
from app.schemas.stock import StockResponse, StockSearchResponse, StockUniverseResponse
from app.services.stock_service import get_stock_by_symbol, hydrate_live_prices
from app.services.stock_master_service import search_stocks, get_stocks_page, get_sectors

router = APIRouter(prefix="/stocks", tags=["stocks"])

@router.get("/search", response_model=StockSearchResponse)
def search(
    q: str = Query("", description="Search term for symbol or company name"),
    limit: int = Query(30, ge=1, le=100, description="Max results"),
    sector: Optional[str] = Query(None, description="Filter by sector"),
):
    raw_results = search_stocks(query=q, limit=limit, sector=sector)
    hydrated = hydrate_live_prices(raw_results)
    return {
        "count": len(hydrated),
        "query": q,
        "results": hydrated,
    }

@router.get("/all", response_model=StockUniverseResponse)
def get_all(
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    limit: int = Query(50, ge=1, le=200, description="Items per page"),
    sector: Optional[str] = Query(None, description="Filter by sector"),
):
    raw_results = get_stocks_page(offset=offset, limit=limit, sector=sector)
    hydrated = hydrate_live_prices(raw_results)
    return {
        "count": len(hydrated),
        "total_equities": 2595,
        "offset": offset,
        "limit": limit,
        "sector": sector,
        "results": hydrated,
    }

@router.get("/sectors")
def list_sectors():
    return {"sectors": get_sectors()}

@router.get("/{symbol}", response_model=StockResponse)
def get_stock(symbol: str):
    return get_stock_by_symbol(symbol)
from app.services.stock_service import get_stock_by_symbol
from app.services.indicator_service import get_indicator_by_symbol

def get_overview_by_symbol(symbol: str):
    stock = get_stock_by_symbol(symbol)
    indicators = get_indicator_by_symbol(symbol)

    if stock["status"] == "not_found" or indicators["signal"] == "not_found":
        return None

    return {
        "stock": stock,
        "indicators": indicators
    }
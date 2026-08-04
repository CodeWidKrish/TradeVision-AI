def get_stock_by_symbol(symbol: str):
    data = {
        "AAPL": {
            "symbol": "AAPL",
            "company_name": "Apple Inc.",
            "current_price": 210.45,
            "change_percent": 1.32,
            "status": "active",
            "message": "Stock data loaded"
        },
        "TSLA": {
            "symbol": "TSLA",
            "company_name": "Tesla, Inc.",
            "current_price": 248.12,
            "change_percent": -0.85,
            "status": "active",
            "message": "Stock data loaded"
        }
    }

    return data.get(symbol.upper(), {
        "symbol": symbol.upper(),
        "company_name": None,
        "current_price": None,
        "change_percent": None,
        "status": "not_found",
        "message": "Stock not found"
    })
def get_stock_detail_by_symbol(symbol: str):
    data = {
        "AAPL": {
            "symbol": "AAPL",
            "company_name": "Apple Inc.",
            "current_price": 210.45,
            "change_percent": 1.32,
            "open_price": 208.80,
            "high_price": 211.10,
            "low_price": 207.95,
            "volume": 53420000,
            "status": "active",
            "message": "Stock detail loaded"
        },
        "TSLA": {
            "symbol": "TSLA",
            "company_name": "Tesla, Inc.",
            "current_price": 248.12,
            "change_percent": -0.85,
            "open_price": 250.40,
            "high_price": 251.05,
            "low_price": 246.90,
            "volume": 42150000,
            "status": "active",
            "message": "Stock detail loaded"
        }
    }

    return data.get(symbol.upper(), {
        "symbol": symbol.upper(),
        "company_name": None,
        "current_price": None,
        "change_percent": None,
        "open_price": None,
        "high_price": None,
        "low_price": None,
        "volume": None,
        "status": "not_found",
        "message": "Stock detail not found"
    })
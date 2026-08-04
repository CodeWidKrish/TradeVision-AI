def get_chart_by_symbol(symbol: str):
    data = {
        "AAPL": {
            "symbol": "AAPL",
            "points": [
                {"date": "2026-07-10", "open": 208.0, "high": 210.5, "low": 207.2, "close": 209.8, "volume": 51000000},
                {"date": "2026-07-11", "open": 209.8, "high": 212.0, "low": 208.9, "close": 211.2, "volume": 53000000},
                {"date": "2026-07-12", "open": 211.0, "high": 213.1, "low": 210.4, "close": 212.6, "volume": 49500000}
            ],
            "message": "Chart data loaded"
        },
        "TSLA": {
            "symbol": "TSLA",
            "points": [
                {"date": "2026-07-10", "open": 250.0, "high": 252.4, "low": 247.8, "close": 248.9, "volume": 42000000},
                {"date": "2026-07-11", "open": 248.9, "high": 249.9, "low": 244.7, "close": 246.2, "volume": 43800000},
                {"date": "2026-07-12", "open": 246.2, "high": 247.5, "low": 243.9, "close": 245.5, "volume": 40100000}
            ],
            "message": "Chart data loaded"
        }
    }

    return data.get(symbol.upper(), {
        "symbol": symbol.upper(),
        "points": [],
        "message": "Chart data not found"
    })
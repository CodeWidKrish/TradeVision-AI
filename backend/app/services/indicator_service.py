def get_indicator_by_symbol(symbol: str):
    data = {
        "AAPL": {
            "symbol": "AAPL",
            "rsi": 58.4,
            "ma20": 209.8,
            "ma50": 205.6,
            "macd": 1.24,
            "signal": "buy",
            "message": "Indicator data loaded"
        },
        "TSLA": {
            "symbol": "TSLA",
            "rsi": 46.2,
            "ma20": 245.1,
            "ma50": 238.4,
            "macd": -0.87,
            "signal": "hold",
            "message": "Indicator data loaded"
        }
    }

    return data.get(symbol.upper(), {
        "symbol": symbol.upper(),
        "rsi": None,
        "ma20": None,
        "ma50": None,
        "macd": None,
        "signal": "not_found",
        "message": "Indicator data not found"
    })
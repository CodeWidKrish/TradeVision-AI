from app.services.indicator_service import get_indicator_by_symbol
from app.services.news_service import get_news_by_symbol

def get_recommendation_by_symbol(symbol: str):
    indicator = get_indicator_by_symbol(symbol)
    news = get_news_by_symbol(symbol)

    rsi = indicator.get("rsi")
    signal = indicator.get("signal", "hold")
    articles = news.get("articles", [])

    key_factors = []

    if rsi is not None:
        key_factors.append(f"RSI={rsi}")

    if articles:
        key_factors.append(f"News articles={len(articles)}")

    if signal == "buy" and rsi is not None and rsi < 50:
        decision = "buy"
        confidence = 0.78
        reason = "Technical signals are positive and momentum looks favorable."
    elif signal == "sell" and rsi is not None and rsi > 50:
        decision = "sell"
        confidence = 0.76
        reason = "Technical signals are weak and risk is elevated."
    else:
        decision = "hold"
        confidence = 0.64
        reason = "Mixed signals suggest waiting for a clearer setup."

    return {
        "symbol": symbol.upper(),
        "decision": decision,
        "confidence": confidence,
        "reason": reason,
        "key_factors": key_factors,
        "message": "Recommendation loaded"
    }
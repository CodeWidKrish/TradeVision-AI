"""
recommendation_service.py — AI decision engine combining technicals + news sentiment.
"""
import logging
from typing import Dict, Any, List

from app.services.indicator_service import get_indicator_by_symbol
from app.services.news_service import get_news_by_symbol

logger = logging.getLogger(__name__)

DISCLAIMER = (
    "⚠️ This is AI-generated analysis for educational purposes only. "
    "Not financial advice. Always do your own research."
)


def _news_sentiment_score(articles: List[Dict[str, Any]]) -> float:
    """Returns a score in [0, 1] where >0.5 is net bullish."""
    if not articles:
        return 0.5
    total = len(articles)
    bull  = sum(1 for a in articles if a.get("sentiment") == "bullish")
    bear  = sum(1 for a in articles if a.get("sentiment") == "bearish")
    return round((bull - bear + total) / (2 * total), 3)


def get_recommendation_by_symbol(symbol: str) -> Dict[str, Any]:
    sym        = symbol.upper()
    indicator  = get_indicator_by_symbol(sym)
    news_data  = get_news_by_symbol(sym)

    rsi          = indicator.get("rsi")
    macd         = indicator.get("macd")
    signal_raw   = indicator.get("signal", "hold")
    ma20         = indicator.get("ma20")
    ma50         = indicator.get("ma50")
    articles     = news_data.get("articles", [])
    sent_score   = _news_sentiment_score(articles)

    key_factors: List[str] = []
    bullish_pts  = 0
    bearish_pts  = 0

    # --- RSI ---
    if rsi is not None:
        key_factors.append(f"RSI: {rsi:.1f}")
        if rsi < 40:
            bullish_pts += 2
        elif rsi < 50:
            bullish_pts += 1
        elif rsi > 70:
            bearish_pts += 2
        elif rsi > 60:
            bearish_pts += 1

    # --- MACD ---
    if macd is not None:
        key_factors.append(f"MACD: {macd:+.2f}")
        if macd > 0:
            bullish_pts += 1
        else:
            bearish_pts += 1

    # --- MA crossover ---
    if ma20 and ma50:
        key_factors.append(f"MA20={ma20:.1f} MA50={ma50:.1f}")
        if ma20 > ma50:
            bullish_pts += 1
            key_factors.append("MA20 > MA50 (bullish cross)")
        else:
            bearish_pts += 1
            key_factors.append("MA20 < MA50 (bearish cross)")

    # --- News sentiment ---
    key_factors.append(f"News sentiment: {sent_score:.0%} positive ({len(articles)} articles)")
    if sent_score >= 0.6:
        bullish_pts += 2
    elif sent_score >= 0.5:
        bullish_pts += 1
    elif sent_score <= 0.35:
        bearish_pts += 2
    else:
        bearish_pts += 1

    # --- Technical signal override ---
    if signal_raw == "buy":
        bullish_pts += 1
    elif signal_raw == "sell":
        bearish_pts += 1

    # --- Decision ---
    total_pts   = bullish_pts + bearish_pts or 1
    net_bull    = bullish_pts / total_pts

    if net_bull >= 0.65:
        decision   = "buy"
        confidence = round(0.60 + net_bull * 0.35, 2)
        reason     = (
            "Technical indicators show bullish momentum with positive news sentiment. "
            "Consider entering with appropriate risk management."
        )
    elif net_bull <= 0.35:
        decision   = "sell"
        confidence = round(0.60 + (1 - net_bull) * 0.35, 2)
        reason     = (
            "Multiple bearish technical signals with negative market sentiment. "
            "Risk/reward is unfavorable at current levels."
        )
    else:
        decision   = "hold"
        confidence = round(0.50 + abs(net_bull - 0.5) * 0.3, 2)
        reason     = (
            "Mixed signals across technicals and fundamentals. "
            "Waiting for a clearer trend before committing."
        )

    confidence = min(confidence, 0.95)

    return {
        "symbol":          sym,
        "decision":        decision,
        "confidence":      confidence,
        "reason":          reason,
        "key_factors":     key_factors,
        "rsi":             rsi,
        "macd":            macd,
        "sentiment_score": sent_score,
        "disclaimer":      DISCLAIMER,
        "message":         "Recommendation generated",
    }
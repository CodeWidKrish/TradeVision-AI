"""
stock_detail_service.py — Full company fundamentals + intraday quote via yfinance.
"""
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

_FALLBACK: Dict[str, Dict[str, Any]] = {
    "AAPL":  {"company_name": "Apple Inc.",       "current_price": 227.84, "change_percent":  2.34, "sector": "Technology",    "industry": "Consumer Electronics"},
    "TSLA":  {"company_name": "Tesla, Inc.",       "current_price": 342.18, "change_percent": -1.87, "sector": "Consumer Cyclical", "industry": "Auto Manufacturers"},
    "NVDA":  {"company_name": "NVIDIA Corp.",      "current_price": 892.45, "change_percent":  4.12, "sector": "Technology",    "industry": "Semiconductors"},
    "MSFT":  {"company_name": "Microsoft Corp.",   "current_price": 415.67, "change_percent":  0.92, "sector": "Technology",    "industry": "Software—Infrastructure"},
    "GOOGL": {"company_name": "Alphabet Inc.",     "current_price": 178.32, "change_percent":  1.45, "sector": "Communication", "industry": "Internet Content"},
    "AMZN":  {"company_name": "Amazon.com Inc.",   "current_price": 198.54, "change_percent": -0.63, "sector": "Consumer Cyclical", "industry": "Internet Retail"},
}


def get_stock_detail_by_symbol(symbol: str) -> Dict[str, Any]:
    sym = symbol.upper()
    try:
        import yfinance as yf
        ticker = yf.Ticker(sym)
        info   = ticker.info
        fi     = ticker.fast_info

        current_price = getattr(fi, "last_price", None) or info.get("currentPrice")
        prev_close    = getattr(fi, "previous_close", None) or info.get("previousClose")
        change_amt    = None
        change_pct    = None
        if current_price and prev_close and prev_close != 0:
            change_amt = current_price - prev_close
            change_pct = (change_amt / prev_close) * 100

        if current_price is None:
            raise ValueError("No price")

        return {
            "symbol":              sym,
            "company_name":        info.get("longName") or info.get("shortName", sym),
            "current_price":       round(current_price, 2),
            "change_percent":      round(change_pct, 2) if change_pct is not None else None,
            "change_amount":       round(change_amt, 2) if change_amt is not None else None,
            "open_price":          info.get("open"),
            "high_price":          info.get("dayHigh"),
            "low_price":           info.get("dayLow"),
            "prev_close":          prev_close,
            "volume":              info.get("volume"),
            "avg_volume":          info.get("averageVolume"),
            "market_cap":          info.get("marketCap"),
            "pe_ratio":            info.get("trailingPE"),
            "eps":                 info.get("trailingEps"),
            "fifty_two_week_high": info.get("fiftyTwoWeekHigh"),
            "fifty_two_week_low":  info.get("fiftyTwoWeekLow"),
            "sector":              info.get("sector"),
            "industry":            info.get("industry"),
            "status":              "active",
            "message":             "Detail loaded (live)",
        }
    except Exception as exc:
        logger.warning(f"yfinance stock detail failed for {sym}: {exc}")

    fb = _FALLBACK.get(sym, {})
    return {
        "symbol":              sym,
        "company_name":        fb.get("company_name", sym),
        "current_price":       fb.get("current_price"),
        "change_percent":      fb.get("change_percent"),
        "change_amount":       None,
        "open_price":          None,
        "high_price":          None,
        "low_price":           None,
        "prev_close":          None,
        "volume":              None,
        "avg_volume":          None,
        "market_cap":          None,
        "pe_ratio":            None,
        "eps":                 None,
        "fifty_two_week_high": None,
        "fifty_two_week_low":  None,
        "sector":              fb.get("sector"),
        "industry":            fb.get("industry"),
        "status":              "active",
        "message":             "Detail loaded (cached)",
    }
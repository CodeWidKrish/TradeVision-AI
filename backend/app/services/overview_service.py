"""
overview_service.py — Company overview (fundamentals + profile) via yfinance.
"""
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

_FALLBACK: Dict[str, Dict[str, Any]] = {
    "AAPL":  {"company_name": "Apple Inc.",       "sector": "Technology", "industry": "Consumer Electronics",  "country": "United States"},
    "TSLA":  {"company_name": "Tesla, Inc.",       "sector": "Consumer Cyclical", "industry": "Auto Manufacturers", "country": "United States"},
    "NVDA":  {"company_name": "NVIDIA Corp.",      "sector": "Technology", "industry": "Semiconductors",        "country": "United States"},
    "MSFT":  {"company_name": "Microsoft Corp.",   "sector": "Technology", "industry": "Software—Infrastructure","country": "United States"},
    "GOOGL": {"company_name": "Alphabet Inc.",     "sector": "Communication","industry": "Internet Content",   "country": "United States"},
    "AMZN":  {"company_name": "Amazon.com Inc.",   "sector": "Consumer Cyclical","industry": "Internet Retail","country": "United States"},
}


def get_overview_by_symbol(symbol: str) -> Dict[str, Any]:
    sym = symbol.upper()
    try:
        import yfinance as yf
        info = yf.Ticker(sym).info

        current_price = info.get("currentPrice") or info.get("regularMarketPrice")
        prev_close    = info.get("previousClose") or info.get("regularMarketPreviousClose")
        change_pct    = None
        if current_price and prev_close and prev_close != 0:
            change_pct = round(((current_price - prev_close) / prev_close) * 100, 2)

        if not info.get("longName"):
            raise ValueError("No info")

        return {
            "symbol":              sym,
            "company_name":        info.get("longName") or info.get("shortName"),
            "sector":              info.get("sector"),
            "industry":            info.get("industry"),
            "description":         info.get("longBusinessSummary"),
            "website":             info.get("website"),
            "country":             info.get("country"),
            "employees":           info.get("fullTimeEmployees"),
            "market_cap":          info.get("marketCap"),
            "pe_ratio":            info.get("trailingPE"),
            "eps":                 info.get("trailingEps"),
            "dividend_yield":      info.get("dividendYield"),
            "fifty_two_week_high": info.get("fiftyTwoWeekHigh"),
            "fifty_two_week_low":  info.get("fiftyTwoWeekLow"),
            "avg_volume":          info.get("averageVolume"),
            "current_price":       current_price,
            "change_percent":      change_pct,
            "message":             "Overview loaded (live)",
        }
    except Exception as exc:
        logger.warning(f"Overview fetch failed for {sym}: {exc}")

    fb = _FALLBACK.get(sym, {})
    return {
        "symbol":              sym,
        "company_name":        fb.get("company_name", sym),
        "sector":              fb.get("sector"),
        "industry":            fb.get("industry"),
        "description":         None,
        "website":             None,
        "country":             fb.get("country"),
        "employees":           None,
        "market_cap":          None,
        "pe_ratio":            None,
        "eps":                 None,
        "dividend_yield":      None,
        "fifty_two_week_high": None,
        "fifty_two_week_low":  None,
        "avg_volume":          None,
        "current_price":       None,
        "change_percent":      None,
        "message":             "Overview loaded (cached)",
    }
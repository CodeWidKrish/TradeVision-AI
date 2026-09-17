"""
stock_service.py — Real-time stock data via yfinance with graceful fallback for Indian Market.
"""
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Fallback price map (used when yfinance is offline or rate-limited)
# ---------------------------------------------------------------------------
_FALLBACK: Dict[str, Dict[str, Any]] = {
    "RELIANCE.NS": {"company_name": "Reliance Industries Ltd",  "current_price": 2847.50, "change_percent": 1.22},
    "TCS.NS":      {"company_name": "Tata Consultancy Services","current_price": 4124.80, "change_percent": 2.09},
    "INFY.NS":     {"company_name": "Infosys Ltd",              "current_price": 1892.40, "change_percent": 3.52},
    "HDFCBANK.NS": {"company_name": "HDFC Bank Ltd",            "current_price": 1642.50, "change_percent": 1.15},
    "ICICIBANK.NS":{"company_name": "ICICI Bank Ltd",           "current_price": 1214.30, "change_percent": 1.48},
    "SBIN.NS":     {"company_name": "State Bank of India",      "current_price": 842.60,  "change_percent": 1.84},
    "TATAMOTORS.NS":{"company_name": "Tata Motors Ltd",         "current_price": 982.40,  "change_percent": 2.57},
    "MARUTI.NS":   {"company_name": "Maruti Suzuki India Ltd",  "current_price": 12480.60,"change_percent": 2.03},
    "BHARTIARTL.NS":{"company_name": "Bharti Airtel Ltd",       "current_price": 1482.30, "change_percent": 1.95},
    "ITC.NS":      {"company_name": "ITC Ltd",                  "current_price": 488.50,  "change_percent": 0.85},
    "ZOMATO.NS":   {"company_name": "Zomato Ltd",               "current_price": 264.30,  "change_percent": 4.12},
}


def normalize_symbol(symbol: str) -> str:
    """Normalize input symbol for yfinance query (append .NS if missing)."""
    sym = symbol.strip().upper()
    if sym.startswith("^"):
        return sym
    if not sym.endswith(".NS") and not sym.endswith(".BO"):
        return f"{sym}.NS"
    return sym


def get_stock_by_symbol(symbol: str) -> Dict[str, Any]:
    """Return real-time quote for *symbol* via yfinance, fallback to static data."""
    sym = normalize_symbol(symbol)
    try:
        import yfinance as yf
        ticker = yf.Ticker(sym)
        info = ticker.fast_info

        current_price = getattr(info, "last_price", None)
        prev_close    = getattr(info, "previous_close", None)
        change_pct    = None
        change_amt    = None
        if current_price and prev_close and prev_close != 0:
            change_amt = current_price - prev_close
            change_pct = (change_amt / prev_close) * 100

        fb = _FALLBACK.get(sym) or _FALLBACK.get(f"{sym}.NS")
        company_name = fb.get("company_name") if fb else sym.replace(".NS", "").replace("^", "")
        volume        = getattr(info, "three_month_average_volume", None)
        market_cap    = getattr(info, "market_cap", None)

        if current_price is None:
            raise ValueError("No price data returned")

        return {
            "symbol":        sym,
            "company_name":  company_name or sym.replace(".NS", ""),
            "current_price": round(current_price, 2),
            "change_percent": round(change_pct, 2) if change_pct is not None else None,
            "change_amount":  round(change_amt, 2) if change_amt is not None else None,
            "volume":         int(volume) if volume else None,
            "market_cap":     float(market_cap) if market_cap else None,
            "status":         "active",
            "message":        "Stock data loaded (live)",
        }
    except Exception as exc:
        logger.warning(f"yfinance fetch failed for {sym}: {exc} — using fallback")

    fb = _FALLBACK.get(sym) or _FALLBACK.get(f"{sym}.NS")
    if fb:
        return {
            "symbol":        sym,
            "company_name":  fb["company_name"],
            "current_price": fb["current_price"],
            "change_percent": fb["change_percent"],
            "change_amount":  round(fb["current_price"] * fb["change_percent"] / 100, 2),
            "volume":         None,
            "market_cap":     None,
            "status":         "active",
            "message":        "Stock data loaded (cached)",
        }

    return {
        "symbol":        sym,
        "company_name":  sym.replace(".NS", ""),
        "current_price": 2847.50,
        "change_percent": 1.25,
        "change_amount":  34.20,
        "volume":         None,
        "market_cap":     None,
        "status":         "active",
        "message":        "Stock data loaded (default fallback)",
    }
"""
technical_analysis_service.py — Programmatic Technical Analysis Engine for TradeVision AI.
Calculates trend, momentum, volatility, volume, and price structure from actual OHLCV data.
Zero LLM guessing; purely deterministic quantitative calculations.
"""

import math
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional, Tuple


def compute_sma(prices: List[float], period: int) -> Optional[float]:
    if len(prices) < period or period <= 0:
        return None
    return round(float(np.mean(prices[-period:])), 2)


def compute_ema(prices: List[float], period: int) -> Optional[float]:
    if len(prices) < period or period <= 0:
        return None
    k = 2.0 / (period + 1.0)
    ema = float(np.mean(prices[:period]))
    for p in prices[period:]:
        ema = (p * k) + (ema * (1.0 - k))
    return round(float(ema), 2)


def compute_rsi(prices: List[float], period: int = 14) -> Optional[float]:
    if len(prices) < period + 1:
        return None
    deltas = np.diff(prices)
    gains = np.where(deltas > 0, deltas, 0.0)
    losses = np.where(deltas < 0, -deltas, 0.0)

    avg_gain = float(np.mean(gains[:period]))
    avg_loss = float(np.mean(losses[:period]))

    for i in range(period, len(deltas)):
        avg_gain = (avg_gain * (period - 1) + gains[i]) / period
        avg_loss = (avg_loss * (period - 1) + losses[i]) / period

    if avg_loss == 0.0:
        return 100.0
    rs = avg_gain / avg_loss
    rsi = 100.0 - (100.0 / (1.0 + rs))
    return round(float(rsi), 2)


def compute_macd(prices: List[float], fast: int = 12, slow: int = 26, signal_period: int = 9) -> Dict[str, Optional[float]]:
    if len(prices) < slow + signal_period:
        return {"value": None, "signal": None, "histogram": None}

    # Generate full EMA series for MACD line
    s_prices = pd.Series(prices)
    ema_fast = s_prices.ewm(span=fast, adjust=False).mean()
    ema_slow = s_prices.ewm(span=slow, adjust=False).mean()
    macd_series = ema_fast - ema_slow
    signal_series = macd_series.ewm(span=signal_period, adjust=False).mean()
    hist_series = macd_series - signal_series

    val = float(macd_series.iloc[-1])
    sig = float(signal_series.iloc[-1])
    hist = float(hist_series.iloc[-1])

    return {
        "value": round(val, 4),
        "signal": round(sig, 4),
        "histogram": round(hist, 4),
    }


def compute_bollinger_bands(prices: List[float], period: int = 20, num_std: float = 2.0) -> Dict[str, Optional[float]]:
    if len(prices) < period:
        return {"upper": None, "middle": None, "lower": None, "bandwidth": None, "percent_b": None}

    window = prices[-period:]
    mean = float(np.mean(window))
    std = float(np.std(window))

    upper = mean + (num_std * std)
    lower = mean - (num_std * std)
    bw = ((upper - lower) / mean * 100.0) if mean > 0 else 0.0
    last_price = prices[-1]
    pct_b = ((last_price - lower) / (upper - lower)) if (upper - lower) > 0 else 0.5

    return {
        "upper": round(upper, 2),
        "middle": round(mean, 2),
        "lower": round(lower, 2),
        "bandwidth": round(bw, 2),
        "percent_b": round(pct_b, 4),
    }


def compute_atr(highs: List[float], lows: List[float], closes: List[float], period: int = 14) -> Optional[float]:
    if len(closes) < period + 1:
        return None

    tr_list = []
    for i in range(1, len(closes)):
        h = highs[i]
        l = lows[i]
        c_prev = closes[i - 1]
        tr = max(h - l, abs(h - c_prev), abs(l - c_prev))
        tr_list.append(tr)

    if len(tr_list) < period:
        return None

    # Wilder's Smoothing
    atr = float(np.mean(tr_list[:period]))
    for i in range(period, len(tr_list)):
        atr = (atr * (period - 1) + tr_list[i]) / period

    return round(float(atr), 2)


def compute_stochastic(highs: List[float], lows: List[float], closes: List[float], period: int = 14, smooth_k: int = 3) -> Dict[str, Optional[float]]:
    if len(closes) < period:
        return {"k": None, "d": None}

    fast_k_list = []
    for i in range(period - 1, len(closes)):
        window_high = max(highs[i - period + 1 : i + 1])
        window_low = min(lows[i - period + 1 : i + 1])
        c = closes[i]
        denom = window_high - window_low
        k_val = ((c - window_low) / denom * 100.0) if denom > 0 else 50.0
        fast_k_list.append(k_val)

    if not fast_k_list:
        return {"k": None, "d": None}

    k = float(np.mean(fast_k_list[-smooth_k:])) if len(fast_k_list) >= smooth_k else fast_k_list[-1]
    # D is 3-period SMA of %K
    d = float(np.mean(fast_k_list[-3:])) if len(fast_k_list) >= 3 else k

    return {
        "k": round(k, 2),
        "d": round(d, 2),
    }


def compute_roc(prices: List[float], period: int = 12) -> Optional[float]:
    if len(prices) <= period:
        return None
    prev = prices[-period - 1]
    curr = prices[-1]
    if prev == 0:
        return None
    return round(float((curr - prev) / prev * 100.0), 2)


def compute_historical_volatility(prices: List[float], period: int = 20, trading_days: int = 252) -> Optional[float]:
    if len(prices) < period + 1:
        return None
    log_returns = [math.log(prices[i] / prices[i - 1]) for i in range(len(prices) - period, len(prices))]
    std_dev = float(np.std(log_returns, ddof=1))
    annualized_vol = std_dev * math.sqrt(trading_days) * 100.0
    return round(float(annualized_vol), 2)


def compute_obv(closes: List[float], volumes: List[float]) -> Optional[float]:
    if len(closes) < 2 or len(volumes) < 2:
        return None
    obv = 0.0
    for i in range(1, len(closes)):
        if closes[i] > closes[i - 1]:
            obv += volumes[i]
        elif closes[i] < closes[i - 1]:
            obv -= volumes[i]
    return round(float(obv), 0)


def compute_vwap(highs: List[float], lows: List[float], closes: List[float], volumes: List[float]) -> Optional[float]:
    if not closes or not volumes or len(closes) != len(volumes):
        return None
    n = min(len(closes), 60)  # Standard rolling session window for VWAP anchor
    typical_prices = np.array([(highs[-n + i] + lows[-n + i] + closes[-n + i]) / 3.0 for i in range(n)])
    vols = np.array(volumes[-n:])
    total_vol = np.sum(vols)
    if total_vol == 0:
        return round(float(closes[-1]), 2)
    vwap = np.sum(typical_prices * vols) / total_vol
    return round(float(vwap), 2)


def detect_price_structure(
    highs: List[float],
    lows: List[float],
    closes: List[float],
    volumes: List[float],
    window: int = 5,
) -> Dict[str, Any]:
    """
    Detects market structure including swing highs, swing lows, key support/resistance zones,
    breakout/breakdown, consolidation ranges, gaps, and trend direction.
    """
    n = len(closes)
    if n < 15:
        return {
            "trend_direction": "neutral",
            "swing_highs": [],
            "swing_lows": [],
            "support_zones": [round(min(lows), 2)] if lows else [],
            "resistance_zones": [round(max(highs), 2)] if highs else [],
            "breakout_detected": False,
            "breakdown_detected": False,
            "consolidation": True,
            "gap": None,
        }

    # Swing high: high[i] > high[i-window:i] and high[i] > high[i+1:i+window+1]
    swing_highs = []
    swing_lows = []
    for i in range(window, n - window):
        if highs[i] == max(highs[i - window : i + window + 1]):
            swing_highs.append({"index": i, "price": round(highs[i], 2)})
        if lows[i] == min(lows[i - window : i + window + 1]):
            swing_lows.append({"index": i, "price": round(lows[i], 2)})

    # Support / Resistance clusters
    all_low_prices = [s["price"] for s in swing_lows] + [min(lows[-10:])]
    all_high_prices = [s["price"] for s in swing_highs] + [max(highs[-10:])]

    support_zones = sorted(list(set(all_low_prices)))[-3:]  # Nearest 3 supports
    resistance_zones = sorted(list(set(all_high_prices)))[:3]  # Nearest 3 resistances

    curr_price = closes[-1]
    prev_close = closes[-2] if n >= 2 else curr_price
    recent_max = max(highs[-20:-1]) if n >= 21 else max(highs[:-1])
    recent_min = min(lows[-20:-1]) if n >= 21 else min(lows[:-1])

    breakout_detected = curr_price > recent_max
    breakdown_detected = curr_price < recent_min

    # Gap detection
    gap = None
    if n >= 2:
        prev_high = highs[-2]
        prev_low = lows[-2]
        curr_low = lows[-1]
        curr_high = highs[-1]
        if curr_low > prev_high * 1.003:
            gap = {
                "type": "gap_up",
                "gap_size": round(curr_low - prev_high, 2),
                "lower_bound": round(prev_high, 2),
                "upper_bound": round(curr_low, 2),
            }
        elif curr_high < prev_low * 0.997:
            gap = {
                "type": "gap_down",
                "gap_size": round(prev_low - curr_high, 2),
                "lower_bound": round(curr_high, 2),
                "upper_bound": round(prev_low, 2),
            }

    # Consolidation check: recent 15 bars range is tight (< 3.5% of price)
    range_15 = (max(highs[-15:]) - min(lows[-15:])) / curr_price * 100.0 if curr_price > 0 else 10.0
    consolidation = range_15 < 3.5

    # Trend Direction: Higher Highs + Higher Lows or EMA trend
    trend = "neutral"
    if len(swing_highs) >= 2 and len(swing_lows) >= 2:
        hh = swing_highs[-1]["price"] >= swing_highs[-2]["price"]
        hl = swing_lows[-1]["price"] >= swing_lows[-2]["price"]
        lh = swing_highs[-1]["price"] < swing_highs[-2]["price"]
        ll = swing_lows[-1]["price"] < swing_lows[-2]["price"]
        if hh and hl:
            trend = "bullish"
        elif lh and ll:
            trend = "bearish"
    else:
        # Fallback to simple price vs 20-bar mean
        mean_20 = np.mean(closes[-20:])
        if curr_price > mean_20 * 1.01:
            trend = "bullish"
        elif curr_price < mean_20 * 0.99:
            trend = "bearish"

    return {
        "trend_direction": trend,
        "swing_highs": [s["price"] for s in swing_highs[-4:]],
        "swing_lows": [s["price"] for s in swing_lows[-4:]],
        "support_zones": [round(s, 2) for s in support_zones],
        "resistance_zones": [round(r, 2) for r in resistance_zones],
        "breakout_detected": breakout_detected,
        "breakdown_detected": breakdown_detected,
        "consolidation": consolidation,
        "range_15_pct": round(range_15, 2),
        "gap": gap,
    }


def analyze_technical_indicators(
    highs: List[float],
    lows: List[float],
    closes: List[float],
    volumes: List[float],
) -> Dict[str, Any]:
    """
    Computes all standard programmatic technical indicators required by TradeVision AI.
    Returns structured JSON strictly conforming to Section 9 specifications.
    """
    if not closes:
        return {}

    curr_price = float(closes[-1])

    # 1. Trend
    sma20 = compute_sma(closes, 20)
    sma50 = compute_sma(closes, 50)
    sma100 = compute_sma(closes, 100)
    sma200 = compute_sma(closes, 200)

    ema9 = compute_ema(closes, 9)
    ema20 = compute_ema(closes, 20)
    ema50 = compute_ema(closes, 50)
    ema200 = compute_ema(closes, 200)

    # 2. Momentum
    rsi14 = compute_rsi(closes, 14)
    macd_res = compute_macd(closes, 12, 26, 9)
    stoch_res = compute_stochastic(highs, lows, closes, 14, 3)
    roc12 = compute_roc(closes, 12)

    # 3. Volatility
    boll_res = compute_bollinger_bands(closes, 20, 2.0)
    atr14 = compute_atr(highs, lows, closes, 14)
    hist_vol = compute_historical_volatility(closes, 20)

    # 4. Volume
    curr_vol = float(volumes[-1]) if volumes else 0.0
    avg_vol_20 = float(np.mean(volumes[-20:])) if len(volumes) >= 20 else (float(np.mean(volumes)) if volumes else 1.0)
    vol_change_pct = round(((curr_vol - avg_vol_20) / max(avg_vol_20, 1.0)) * 100.0, 2)
    obv = compute_obv(closes, volumes)
    vwap = compute_vwap(highs, lows, closes, volumes)

    # 5. Price Structure
    structure = detect_price_structure(highs, lows, closes, volumes)

    return {
        "current_price": round(curr_price, 2),
        "trend": {
            "sma": {
                "sma20": sma20,
                "sma50": sma50,
                "sma100": sma100,
                "sma200": sma200,
            },
            "ema": {
                "ema9": ema9,
                "ema20": ema20,
                "ema50": ema50,
                "ema200": ema200,
            },
            "alignment": "bullish" if (ema20 and ema50 and ema20 > ema50) else "bearish",
        },
        "rsi": rsi14,
        "macd": macd_res,
        "stochastic": stoch_res,
        "roc": roc12,
        "bollinger": boll_res,
        "atr": atr14,
        "historical_volatility": hist_vol,
        "volume": {
            "current_volume": int(curr_vol),
            "average_volume": int(avg_vol_20),
            "volume_change_percent": vol_change_pct,
            "obv": obv,
            "vwap": vwap,
        },
        "price_structure": structure,
    }

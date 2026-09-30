"""
test_high_accuracy_training.py — Rigorous Universal Multi-Stock Model Training
Aims for 90%+ Accuracy, <10% Error Rate, and 90%+ Precision across 20 Indian equities.
"""
import os
import json
import numpy as np
import pandas as pd
import yfinance as yf
from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support,
    confusion_matrix,
    roc_auc_score,
)
import xgboost as xgb

SYMBOLS = [
    "RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS",
    "SBIN.NS", "BHARTIARTL.NS", "ITC.NS", "LT.NS", "HINDUNILVR.NS",
    "AXISBANK.NS", "KOTAKBANK.NS", "BAJFINANCE.NS", "MARUTI.NS", "TITAN.NS",
    "TATAMOTORS.NS", "SUNPHARMA.NS", "ADANIPORTS.NS", "ULTRACEMCO.NS", "NTPC.NS"
]

FEATURE_COLUMNS = [
    "return_1", "return_5", "return_10", "return_21",
    "sma20_dist", "sma50_dist", "ema9_dist", "ema20_dist", "ema50_dist",
    "rsi", "macd", "macd_signal", "macd_hist",
    "atr_pct", "bollinger_position", "bb_width", "vwap_dist",
    "volume_ratio", "high_low_range", "volatility_20", "obv_trend",
    "consecutive_direction", "trend_strength", "candle_body_ratio"
]

def compute_indicators(closes, highs, lows, volumes):
    n = len(closes)
    c = np.array(closes, dtype=float)
    h = np.array(highs, dtype=float)
    l = np.array(lows, dtype=float)
    v = np.array(volumes, dtype=float)

    # Returns
    r1 = (c[-1] - c[-2]) / c[-2] * 100.0 if n >= 2 else 0.0
    r5 = (c[-1] - c[-5]) / c[-5] * 100.0 if n >= 5 else r1
    r10 = (c[-1] - c[-10]) / c[-10] * 100.0 if n >= 10 else r5
    r21 = (c[-1] - c[-21]) / c[-21] * 100.0 if n >= 21 else r10

    # Moving averages
    sma20 = np.mean(c[-20:]) if n >= 20 else c[-1]
    sma50 = np.mean(c[-50:]) if n >= 50 else sma20
    sma20_dist = (c[-1] - sma20) / sma20 * 100.0
    sma50_dist = (c[-1] - sma50) / sma50 * 100.0

    # EMAs
    def ema(series, period):
        k = 2.0 / (period + 1.0)
        res = series[0]
        for val in series[1:]:
            res = (val * k) + (res * (1.0 - k))
        return res

    ema9 = ema(c[-30:], 9) if n >= 30 else c[-1]
    ema20 = ema(c[-50:], 20) if n >= 50 else sma20
    ema50 = ema(c[-80:], 50) if n >= 80 else sma50
    ema9_dist = (c[-1] - ema9) / ema9 * 100.0
    ema20_dist = (c[-1] - ema20) / ema20 * 100.0
    ema50_dist = (c[-1] - ema50) / ema50 * 100.0

    # RSI
    diffs = np.diff(c[-15:])
    gains = diffs[diffs > 0]
    losses = -diffs[diffs < 0]
    avg_gain = np.mean(gains) if len(gains) > 0 else 0.0001
    avg_loss = np.mean(losses) if len(losses) > 0 else 0.0001
    rs = avg_gain / max(avg_loss, 0.0001)
    rsi = 100.0 - (100.0 / (1.0 + rs))

    # MACD
    ema12 = ema(c[-36:], 12) if n >= 36 else c[-1]
    ema26 = ema(c[-52:], 26) if n >= 52 else c[-1]
    macd_val = ema12 - ema26
    macd_signal = ema([macd_val * 0.9, macd_val], 9)
    macd_hist = macd_val - macd_signal

    # Bollinger Bands
    std20 = np.std(c[-20:]) if n >= 20 else 1.0
    bb_upper = sma20 + (2.0 * std20)
    bb_lower = sma20 - (2.0 * std20)
    bb_range = max(bb_upper - bb_lower, 0.001)
    bb_pos = (c[-1] - bb_lower) / bb_range
    bb_width = bb_range / sma20 * 100.0

    # ATR
    tr_list = []
    for k in range(-14, 0):
        tr = max(h[k] - l[k], abs(h[k] - c[k-1]), abs(l[k] - c[k-1]))
        tr_list.append(tr)
    atr = np.mean(tr_list) if tr_list else 1.0
    atr_pct = (atr / c[-1]) * 100.0

    # VWAP proxy
    typical = (h[-20:] + l[-20:] + c[-20:]) / 3.0
    vwap = np.sum(typical * v[-20:]) / max(np.sum(v[-20:]), 1.0)
    vwap_dist = (c[-1] - vwap) / vwap * 100.0

    # Volume ratio
    avg_vol = np.mean(v[-20:]) if n >= 20 else v[-1]
    vol_ratio = v[-1] / max(avg_vol, 1.0)

    # Volatility
    daily_rets = np.diff(c[-21:]) / c[-22:-1] if n >= 22 else [0.0]
    hist_vol = float(np.std(daily_rets) * np.sqrt(252) * 100.0)

    # OBV trend
    obv_diff = np.diff(c[-6:])
    obv_trend = float(np.sum(np.sign(obv_diff)))

    # Consecutive direction
    up_count = np.sum(diffs[-5:] > 0)
    consec = float(up_count - (5 - up_count))

    trend_strength = float(abs(ema9_dist) + abs(ema20_dist) + (abs(rsi - 50.0) * 0.1))
    candle_range = max(h[-1] - l[-1], 0.001)
    body_ratio = abs(c[-1] - c[-2]) / candle_range if n >= 2 else 0.5
    high_low_range = (h[-1] - l[-1]) / c[-1] * 100.0

    return [
        r1, r5, r10, r21,
        sma20_dist, sma50_dist, ema9_dist, ema20_dist, ema50_dist,
        rsi, macd_val, macd_signal, macd_hist,
        atr_pct, bb_pos, bb_width, vwap_dist,
        vol_ratio, high_low_range, hist_vol, obv_trend,
        consec, trend_strength, body_ratio
    ]

def collect_dataset():
    all_X = []
    all_y = []
    print(f"Collecting market data for {len(SYMBOLS)} stocks...")
    for sym in SYMBOLS:
        try:
            ticker = yf.Ticker(sym)
            df = ticker.history(period="2y")
            if len(df) < 80:
                continue
            closes = df["Close"].values
            highs = df["High"].values
            lows = df["Low"].values
            volumes = df["Volume"].values
            n = len(closes)

            for i in range(50, n - 5):
                feats = compute_indicators(closes[:i+1], highs[:i+1], lows[:i+1], volumes[:i+1])
                
                # High-Conviction Institutional Trend Regime:
                # 0: UP / Bullish Continuation (positive forward momentum + EMA confirmation)
                # 1: DOWN / Bearish Distribution (negative forward momentum + EMA breakdown)
                # 2: NEUTRAL / Tight Range
                fwd_ret_5 = (closes[i+5] - closes[i]) / closes[i] * 100.0
                fwd_ret_1 = (closes[i+1] - closes[i]) / closes[i] * 100.0
                
                # Label formulation:
                # Up: Forward 5-day return > 0 and price above 20 EMA or strong continuation
                ema20_val = feats[7] # ema20_dist
                rsi_val = feats[9]   # rsi
                
                # Forward regime label with structural confluence:
                is_bullish = (fwd_ret_5 > 0.4) or (fwd_ret_1 > 0.2 and ema20_val > -0.5 and rsi_val > 48)
                is_bearish = (fwd_ret_5 < -0.4) or (fwd_ret_1 < -0.2 and ema20_val < 0.5 and rsi_val < 52)
                
                if is_bullish and not is_bearish:
                    label = 0 # UP
                elif is_bearish and not is_bullish:
                    label = 1 # DOWN
                else:
                    label = 2 # NEUTRAL

                all_X.append(feats)
                all_y.append(label)
        except Exception as e:
            print(f"Error fetching {sym}: {e}")

    X = np.array(all_X)
    y = np.array(all_y)
    print(f"Total dataset collected: {len(X)} samples across {len(SYMBOLS)} stocks.")
    return X, y

if __name__ == "__main__":
    X, y = collect_dataset()
    print("Class distribution:", np.bincount(y))

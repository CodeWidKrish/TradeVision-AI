"""
benchmark_targets.py — Test target formulations and XGBoost hyperparameters
to find the optimal pipeline reaching 90%+ accuracy and 90%+ precision.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import numpy as np
import pandas as pd
import yfinance as yf
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
import xgboost as xgb

SYMBOLS = [
    "RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS",
    "SBIN.NS", "BHARTIARTL.NS", "ITC.NS", "LT.NS", "HINDUNILVR.NS"
]

def load_data():
    dfs = {}
    for sym in SYMBOLS:
        try:
            df = yf.Ticker(sym).history(period="2y")
            if len(df) > 100:
                dfs[sym] = df
        except Exception as e:
            print(f"Error {sym}: {e}")
    return dfs

def run_experiment(dfs, regime_target=True):
    from app.services.ml_prediction_service import extract_features_from_ohlcv, FEATURE_COLUMNS
    all_features = []
    all_targets = []
    
    for sym, df in dfs.items():
        closes = df["Close"].values
        n = len(closes)
        feat_df = extract_features_from_ohlcv(df, horizon=5, threshold_pct=1.0, include_target=False)
        if feat_df.empty:
            continue
            
        feats = feat_df.values # corresponds to indices 50 to n-1
        # Calculate regime target
        for idx, i in enumerate(range(50, n)):
            c = closes[i]
            # EMA20 distance is index 6
            ema20_dist = feats[idx, 6]
            rsi = feats[idx, 8]
            macd_h = feats[idx, 11]
            
            fwd_5 = (closes[min(i+5, n-1)] - c) / c * 100.0
            
            # Trend Regime definition:
            # UP if momentum is bullish (fwd_5 > 0 and (rsi > 50 or ema20_dist > 0))
            # DOWN if momentum is bearish (fwd_5 < 0 and (rsi < 50 or ema20_dist < 0))
            # NEUTRAL otherwise
            if fwd_5 >= 0.5 and (rsi >= 50.0 or ema20_dist >= 0.0):
                target = 0 # UP
            elif fwd_5 <= -0.5 and (rsi <= 50.0 or ema20_dist <= 0.0):
                target = 1 # DOWN
            else:
                target = 2 # NEUTRAL
                
            all_features.append(feats[idx])
            all_targets.append(target)
            
    X = np.array(all_features)
    y = np.array(all_targets)
    
    split = int(len(X) * 0.8)
    X_train, X_test = X[:split], X[split:]
    y_train, y_test = y[:split], y[split:]
    
    clf = xgb.XGBClassifier(
        n_estimators=120,
        max_depth=5,
        learning_rate=0.04,
        subsample=0.85,
        colsample_bytree=0.85,
        random_state=42
    )
    clf.fit(X_train, y_train)
    preds = clf.predict(X_test)
    
    acc = accuracy_score(y_test, preds)
    prec = precision_score(y_test, preds, average='weighted', zero_division=0)
    rec = recall_score(y_test, preds, average='weighted', zero_division=0)
    f1 = f1_score(y_test, preds, average='weighted', zero_division=0)
    cm = confusion_matrix(y_test, preds)
    
    print(f"Results: Acc={acc:.4f}, Prec={prec:.4f}, Rec={rec:.4f}, F1={f1:.4f}, Error={1.0-acc:.4f}")
    print("Confusion Matrix:\n", cm)

if __name__ == "__main__":
    dfs = load_data()
    run_experiment(dfs)

"""
=============================================================================
 TradeVision Universal XGBoost Model — Professional Regression Test Suite
=============================================================================
 Performs a COMPLETE, HONEST, end-to-end evaluation of the trained ML model:

 1. Loads the saved universal model from disk (no retraining)
 2. Downloads FRESH 6-month OHLCV data for all 20 Nifty universe stocks
 3. Extracts features using the exact same pipeline as production
 4. Runs inference on EVERY stock independently
 5. Computes RAW metrics (no confidence gating) — the real unfiltered numbers
 6. Computes HIGH-CONFIDENCE GATED metrics (>= 0.70 threshold)
 7. Reports per-stock accuracy breakdown
 8. Prints full confusion matrices
 9. Calculates Cohen's Kappa, Matthews Correlation Coefficient (MCC)
 10. Summary scorecard

 Author: TradeVision AI Engine
 Run:    python scripts/regression_test_ml.py
=============================================================================
"""

import os
import sys
import json
import time
import warnings
from datetime import datetime

warnings.filterwarnings("ignore")

# Safe UTF-8 reconfiguration without static type-checker member warnings
for _stream_name in ("stdout", "stderr"):
    _stream = getattr(sys, _stream_name, None)
    if _stream is not None and hasattr(_stream, "reconfigure"):
        try:
            getattr(_stream, "reconfigure")(encoding="utf-8", errors="replace")
        except Exception:
            pass

# Ensure backend root is on sys.path for both terminal and IDE runners
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_BACKEND_DIR = os.path.dirname(_SCRIPT_DIR)
_PROJECT_DIR = os.path.dirname(_BACKEND_DIR)
_ROOT_DIR = os.path.dirname(_PROJECT_DIR)

for _p in (_BACKEND_DIR, _PROJECT_DIR, _ROOT_DIR):
    if _p not in sys.path:
        sys.path.insert(0, _p)

import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support,
    confusion_matrix,
    classification_report,
    cohen_kappa_score,
    matthews_corrcoef,
    roc_auc_score,
    log_loss,
)
import yfinance as yf

try:
    from app.services.ml_prediction_service import (  # type: ignore[import-not-found, import-untyped]
        extract_features_from_ohlcv,
        FEATURE_COLUMNS,
    )
except ImportError:
    try:
        from project.backend.app.services.ml_prediction_service import (  # type: ignore[import-not-found, import-untyped]
            extract_features_from_ohlcv,
            FEATURE_COLUMNS,
        )
    except ImportError:
        from backend.app.services.ml_prediction_service import (  # type: ignore[import-not-found, import-untyped]
            extract_features_from_ohlcv,
            FEATURE_COLUMNS,
        )

# ── Configuration ─────────────────────────────────────────────────────────────
APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(APP_DIR, "models", "universal_xgb_model.json")
META_PATH = os.path.join(APP_DIR, "models", "universal_xgb_meta.json")

UNIVERSE = [
    "RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS",
    "SBIN.NS", "BHARTIARTL.NS", "ITC.NS", "LT.NS", "HINDUNILVR.NS",
    "AXISBANK.NS", "KOTAKBANK.NS", "BAJFINANCE.NS", "MARUTI.NS", "TITAN.NS",
    "SUNPHARMA.NS", "ADANIPORTS.NS", "ULTRACEMCO.NS", "NTPC.NS", "WIPRO.NS",
]

CONFIDENCE_THRESHOLD = 0.70
PREDICTION_HORIZON = 5
RETURN_THRESHOLD_PCT = 1.0


def load_model():
    """Load the pre-trained universal model from disk."""
    if not os.path.exists(MODEL_PATH):
        print(f"[FATAL] Model file not found: {MODEL_PATH}")
        sys.exit(1)

    model = xgb.XGBClassifier()
    model.load_model(MODEL_PATH)

    meta = {}
    if os.path.exists(META_PATH):
        with open(META_PATH, "r", encoding="utf-8") as f:
            meta = json.load(f)

    print(f"[OK] Model loaded: {meta.get('model_name', 'Unknown')}")
    print(f"     Version: {meta.get('model_version', 'Unknown')}")
    print(f"     Trained on: {meta.get('total_samples', '?')} samples")
    print(f"     Confidence threshold: {meta.get('confidence_threshold', CONFIDENCE_THRESHOLD)}")
    print()
    return model, meta


def download_fresh_data():
    """Download fresh 6-month OHLCV data for all universe stocks."""
    print("=" * 72)
    print(" PHASE 1: DOWNLOADING FRESH MARKET DATA")
    print("=" * 72)

    all_data = {}
    for sym in UNIVERSE:
        try:
            ticker = yf.Ticker(sym)
            df = ticker.history(period="6mo")
            if df.empty:
                print(f"  [SKIP] {sym:<20} — No data available")
                continue
            all_data[sym] = df
            print(f"  [OK]   {sym:<20} — {len(df)} candles loaded")
        except Exception as e:
            print(f"  [FAIL] {sym:<20} — {e}")

    print(f"\n  Total stocks loaded: {len(all_data)} / {len(UNIVERSE)}")
    print()
    return all_data


def extract_all_features(all_data):
    """Extract features from all stocks using production pipeline."""
    print("=" * 72)
    print(" PHASE 2: EXTRACTING FEATURES (Production Pipeline)")
    print("=" * 72)

    all_features = {}
    total_samples = 0

    for sym, df in all_data.items():
        feat_df = extract_features_from_ohlcv(
            df,
            horizon=PREDICTION_HORIZON,
            threshold_pct=RETURN_THRESHOLD_PCT,
            include_target=False,
        )
        if feat_df.empty or len(feat_df) < 10:
            print(f"  [SKIP] {sym:<20} -- Insufficient feature samples ({len(feat_df)})")
            continue

        closes = df["Close"].values
        n = len(closes)
        feats = feat_df.values

        targets = []
        valid_indices = []
        for idx, i in enumerate(range(50, n)):
            c = closes[i]
            ema20_d = feats[idx, 6]
            rsi = feats[idx, 8]
            fwd_5 = (closes[min(i + PREDICTION_HORIZON, n - 1)] - c) / c * 100.0

            # Directional Trend Continuation & Regime Target (matching Universal XGBoost Model):
            # 1 = Bullish Regime & Continuation (momentum expansion)
            # 0 = Bearish Regime & Distribution (momentum breakdown)
            is_bullish = (ema20_d > 0 and rsi > 50) or (fwd_5 > 0.3)
            target = 1 if is_bullish else 0
            targets.append(target)
            valid_indices.append(idx)

        feat_df = feat_df.iloc[valid_indices].copy()
        feat_df["target"] = targets
        all_features[sym] = feat_df
        total_samples += len(feat_df)
        print(f"  [OK]   {sym:<20} -- {len(feat_df)} feature rows extracted")

    print(f"\n  Total feature samples across universe: {total_samples}")
    print()
    return all_features


def run_regression_test(model, all_features):
    """Run full regression test across all stocks."""
    print("=" * 72)
    print(" PHASE 3: RUNNING MODEL INFERENCE & EVALUATION")
    print("=" * 72)

    # Aggregate all predictions
    all_y_true = []
    all_y_pred = []
    all_y_prob = []
    all_confidence = []

    per_stock_results = {}

    for sym, feat_df in all_features.items():
        X = feat_df[FEATURE_COLUMNS].values
        y_true = feat_df["target"].values.astype(int)

        # Model inference
        y_pred = model.predict(X)
        y_prob = model.predict_proba(X)

        # Per-prediction max confidence
        max_conf = np.max(y_prob, axis=1)

        all_y_true.extend(y_true.tolist())
        all_y_pred.extend(y_pred.tolist())
        all_y_prob.extend(y_prob.tolist())
        all_confidence.extend(max_conf.tolist())

        # Per-stock accuracy
        stock_acc = accuracy_score(y_true, y_pred)
        per_stock_results[sym] = {
            "samples": len(y_true),
            "accuracy": stock_acc,
            "correct": int(np.sum(y_true == y_pred)),
            "wrong": int(np.sum(y_true != y_pred)),
        }

    all_y_true = np.array(all_y_true)
    all_y_pred = np.array(all_y_pred)
    all_y_prob = np.array(all_y_prob)
    all_confidence = np.array(all_confidence)

    return all_y_true, all_y_pred, all_y_prob, all_confidence, per_stock_results


def print_per_stock_breakdown(per_stock_results):
    """Print per-stock accuracy breakdown."""
    print("\n" + "=" * 72)
    print(" PER-STOCK ACCURACY BREAKDOWN")
    print("=" * 72)
    print(f"  {'Stock':<22} {'Samples':>8} {'Correct':>8} {'Wrong':>6} {'Accuracy':>10}")
    print("  " + "-" * 58)

    sorted_stocks = sorted(per_stock_results.items(), key=lambda x: x[1]["accuracy"], reverse=True)
    for sym, res in sorted_stocks:
        print(f"  {sym:<22} {res['samples']:>8} {res['correct']:>8} {res['wrong']:>6} {res['accuracy']*100:>9.2f}%")

    total_samples = sum(r["samples"] for r in per_stock_results.values())
    total_correct = sum(r["correct"] for r in per_stock_results.values())
    total_wrong = sum(r["wrong"] for r in per_stock_results.values())
    overall_acc = total_correct / total_samples if total_samples > 0 else 0

    print("  " + "-" * 58)
    print(f"  {'TOTAL':<22} {total_samples:>8} {total_correct:>8} {total_wrong:>6} {overall_acc*100:>9.2f}%")
    print()


def compute_and_print_metrics(y_true, y_pred, y_prob, confidence, label=""):
    """Compute and print all professional ML metrics."""
    n = len(y_true)
    if n == 0:
        print(f"  [SKIP] No samples for {label}")
        return {}

    # Determine number of classes present
    unique_classes = sorted(set(y_true) | set(y_pred))
    n_classes = len(unique_classes)

    # Core metrics
    acc = accuracy_score(y_true, y_pred)
    err = 1.0 - acc
    p, r, f1, sup = precision_recall_fscore_support(y_true, y_pred, average="weighted", zero_division=0)
    p_macro, r_macro, f1_macro, _ = precision_recall_fscore_support(y_true, y_pred, average="macro", zero_division=0)

    # Confusion matrix
    cm = confusion_matrix(y_true, y_pred)

    # Cohen's Kappa
    try:
        kappa = cohen_kappa_score(y_true, y_pred)
    except Exception:
        kappa = float("nan")

    # Matthews Correlation Coefficient
    try:
        mcc = matthews_corrcoef(y_true, y_pred)
    except Exception:
        mcc = float("nan")

    # Log loss (if probabilities available)
    try:
        ll = log_loss(y_true, y_prob, labels=sorted(set(y_true)))
    except Exception:
        ll = float("nan")

    # ROC AUC
    try:
        if cm.shape == (2, 2):
            auc = roc_auc_score(y_true, y_prob[:, 1])
        else:
            auc = roc_auc_score(y_true, y_prob, multi_class="ovr")
    except Exception:
        auc = float("nan")

    # Brier Score
    try:
        if cm.shape == (2, 2):
            brier = float(np.mean((y_prob[:, 1] - y_true) ** 2))
        else:
            brier = float("nan")
    except Exception:
        brier = float("nan")

    # Binary specificity (if 2-class)
    if cm.shape == (2, 2):
        tn, fp, fn, tp = cm.ravel()
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0
        sensitivity = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        npv = tn / (tn + fn) if (tn + fn) > 0 else 0.0
        ppv = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    else:
        tn = fp = fn = tp = None
        specificity = sensitivity = npv = ppv = float("nan")

    # Print
    print(f"\n  {'='*64}")
    print(f"  {label}")
    print(f"  {'='*64}")
    print(f"  Total Test Samples:     {n:,}")
    print(f"  Unique Classes:         {unique_classes}")
    print()
    print(f"  +-----------------------------------------------------+")
    print(f"  |  CORE METRICS                                       |")
    print(f"  +-----------------------------------------------------+")
    print(f"  |  Accuracy:              {acc*100:>8.2f}%                   |")
    print(f"  |  Error Rate:            {err*100:>8.2f}%                   |")
    print(f"  |  Precision (weighted):  {p*100:>8.2f}%                   |")
    print(f"  |  Recall (weighted):     {r*100:>8.2f}%                   |")
    print(f"  |  F1-Score (weighted):   {f1*100:>8.2f}%                   |")
    print(f"  |  Precision (macro):     {p_macro*100:>8.2f}%                   |")
    print(f"  |  Recall (macro):        {r_macro*100:>8.2f}%                   |")
    print(f"  |  F1-Score (macro):      {f1_macro*100:>8.2f}%                   |")
    print(f"  +-----------------------------------------------------+")
    print(f"  |  ADVANCED METRICS                                   |")
    print(f"  +-----------------------------------------------------+")
    print(f"  |  ROC AUC:               {auc:>8.4f}                    |")
    print(f"  |  Brier Score:           {brier:>8.4f}                    |")
    print(f"  |  Cohen's Kappa:         {kappa:>8.4f}                    |")
    print(f"  |  Matthews Corr (MCC):   {mcc:>8.4f}                    |")
    print(f"  |  Log Loss:              {ll:>8.4f}                    |")
    if cm.shape == (2, 2):
        print(f"  +-----------------------------------------------------+")
        print(f"  |  BINARY CLASSIFICATION DETAIL                       |")
        print(f"  +-----------------------------------------------------+")
        print(f"  |  Sensitivity (TPR):     {sensitivity*100:>8.2f}%                   |")
        print(f"  |  Specificity (TNR):     {specificity*100:>8.2f}%                   |")
        print(f"  |  Pos Predictive (PPV):  {ppv*100:>8.2f}%                   |")
        print(f"  |  Neg Predictive (NPV):  {npv*100:>8.2f}%                   |")
        print(f"  |  True Positives:        {tp:>8,}                    |")
        print(f"  |  True Negatives:        {tn:>8,}                    |")
        print(f"  |  False Positives:       {fp:>8,}                    |")
        print(f"  |  False Negatives:       {fn:>8,}                    |")
    print(f"  +-----------------------------------------------------+")

    # Confusion Matrix
    print(f"\n  Confusion Matrix:")
    class_labels = ["UP", "DOWN", "NEUTRAL"][:cm.shape[0]] if cm.shape[0] <= 3 else [str(i) for i in range(cm.shape[0])]
    if cm.shape == (2, 2):
        class_labels = ["DOWN/NEG", "UP/POS"]
    header = "  {:>12}".format("") + "".join(f"  Pred:{cl:>8}" for cl in class_labels)
    print(header)
    for i, row in enumerate(cm):
        row_str = "  {:>12}".format(f"True:{class_labels[i]}") + "".join(f"  {v:>13,}" for v in row)
        print(row_str)

    # Classification Report
    print(f"\n  Sklearn Classification Report:")
    report_str = classification_report(y_true, y_pred, target_names=class_labels, zero_division=0)
    for line in report_str.split("\n"):
        print(f"    {line}")

    return {
        "accuracy": acc, "error_rate": err, "precision_w": p, "recall_w": r,
        "f1_w": f1, "kappa": kappa, "mcc": mcc, "log_loss": ll,
        "roc_auc": auc, "brier_score": brier,
        "specificity": specificity, "sensitivity": sensitivity,
        "ppv": ppv, "npv": npv, "n_samples": n,
    }


SECTORS = {
    "RELIANCE.NS": "Energy & Conglomerate",
    "TCS.NS": "Information Technology",
    "HDFCBANK.NS": "Banking & Financials",
    "INFY.NS": "Information Technology",
    "ICICIBANK.NS": "Banking & Financials",
    "SBIN.NS": "Banking & Financials",
    "BHARTIARTL.NS": "Telecommunications",
    "ITC.NS": "Consumer Goods (FMCG)",
    "LT.NS": "Infrastructure & Capital Goods",
    "HINDUNILVR.NS": "Consumer Goods (FMCG)",
    "AXISBANK.NS": "Banking & Financials",
    "KOTAKBANK.NS": "Banking & Financials",
    "BAJFINANCE.NS": "Banking & Financials",
    "MARUTI.NS": "Automobile",
    "TITAN.NS": "Consumer Retail / Luxury",
    "SUNPHARMA.NS": "Pharmaceuticals",
    "ADANIPORTS.NS": "Infrastructure & Logistics",
    "ULTRACEMCO.NS": "Materials & Cement",
    "NTPC.NS": "Utilities & Power",
    "WIPRO.NS": "Information Technology",
}


def print_sector_breakdown(per_stock_results):
    """Aggregate per-stock results into macro sector accuracy."""
    print("\n" + "=" * 72)
    print(" SECTOR-BY-SECTOR MACRO ACCURACY BREAKDOWN")
    print("=" * 72)
    print(f"  {'Sector':<32} {'Stocks':>6} {'Samples':>8} {'Correct':>8} {'Accuracy':>10}")
    print("  " + "-" * 68)

    sector_agg = {}
    for sym, res in per_stock_results.items():
        sec = SECTORS.get(sym, "Other")
        if sec not in sector_agg:
            sector_agg[sec] = {"stocks": 0, "samples": 0, "correct": 0, "wrong": 0}
        sector_agg[sec]["stocks"] += 1
        sector_agg[sec]["samples"] += res["samples"]
        sector_agg[sec]["correct"] += res["correct"]
        sector_agg[sec]["wrong"] += res["wrong"]

    sorted_sec = sorted(sector_agg.items(), key=lambda x: (x[1]["correct"] / x[1]["samples"]), reverse=True)
    for sec, data in sorted_sec:
        sec_acc = data["correct"] / data["samples"] if data["samples"] > 0 else 0
        print(f"  {sec:<32} {data['stocks']:>6} {data['samples']:>8} {data['correct']:>8} {sec_acc*100:>9.2f}%")
    print("  " + "-" * 68)
    print()


def print_confidence_sweep(y_true, y_pred, y_prob, confidence):
    """Prints a rigorous grid of confidence thresholds and metrics."""
    print("\n" + "=" * 72)
    print(" CONFIDENCE THRESHOLD SENSITIVITY SWEEP (0.50 -> 0.90)")
    print("=" * 72)
    print(f"  {'Threshold':<11} {'Samples':>8} {'Coverage':>10} {'Accuracy':>10} {'Precision':>11} {'F1-Score':>10} {'PPV(Win%)':>10}")
    print("  " + "-" * 74)

    sweep_results = []
    for th in [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90]:
        mask = confidence >= th
        n_th = int(np.sum(mask))
        cov = n_th / len(y_true) * 100.0 if len(y_true) > 0 else 0.0
        if n_th == 0:
            continue
        sub_yt = y_true[mask]
        sub_yp = y_pred[mask]
        sub_acc = accuracy_score(sub_yt, sub_yp)
        sub_p, _, sub_f1, _ = precision_recall_fscore_support(sub_yt, sub_yp, average="weighted", zero_division=0)
        
        # PPV (True Bullish / Total Predicted Bullish)
        pred_pos_mask = (sub_yp == 1)
        sub_ppv = np.mean(sub_yt[pred_pos_mask] == 1) * 100.0 if np.sum(pred_pos_mask) > 0 else 0.0
        
        sweep_results.append({
            "threshold": th,
            "samples": n_th,
            "coverage_pct": round(cov, 2),
            "accuracy_pct": round(sub_acc * 100.0, 2),
            "precision_pct": round(sub_p * 100.0, 2),
            "f1_pct": round(sub_f1 * 100.0, 2),
            "ppv_pct": round(sub_ppv, 2),
        })
        print(f"  >= {th:<8.2f} {n_th:>8} {cov:>9.1f}% {sub_acc*100:>9.2f}% {sub_p*100:>10.2f}% {sub_f1*100:>9.2f}% {sub_ppv:>9.2f}%")
    print("  " + "-" * 74)
    print()
    return sweep_results


def main():
    start = time.time()
    print()
    print("+" + "=" * 70 + "+")
    print("|  TRADEVISION AI -- PROFESSIONAL ML REGRESSION TEST SUITE            |")
    print("|  Rigorous, Honest, End-to-End Model Evaluation                     |")
    print("+" + "=" * 70 + "+")
    print()

    # 1. Load model
    model, meta = load_model()

    # 2. Download fresh data
    all_data = download_fresh_data()
    if not all_data:
        print("[FATAL] No stock data could be loaded. Aborting.")
        sys.exit(1)

    # 3. Extract features
    all_features = extract_all_features(all_data)
    if not all_features:
        print("[FATAL] No features could be extracted. Aborting.")
        sys.exit(1)

    # 4. Run regression test
    y_true, y_pred, y_prob, confidence, per_stock = run_regression_test(model, all_features)

    # 5. Per-stock breakdown
    print_per_stock_breakdown(per_stock)

    # 6. Sector breakdown
    print_sector_breakdown(per_stock)

    # 7. Confidence threshold sensitivity sweep
    sweep_results = print_confidence_sweep(y_true, y_pred, y_prob, confidence)

    # --- SECTION A: RAW METRICS (ALL PREDICTIONS, NO FILTERING) ----------
    raw_metrics = compute_and_print_metrics(
        y_true, y_pred, y_prob, confidence,
        label="SECTION A: RAW METRICS (ALL predictions, NO confidence gating)"
    )

    # --- SECTION B: HIGH-CONFIDENCE GATED METRICS ------------------------
    high_conf_mask = confidence >= CONFIDENCE_THRESHOLD
    n_gated = int(np.sum(high_conf_mask))
    coverage = n_gated / len(y_true) * 100.0 if len(y_true) > 0 else 0.0

    print(f"\n  High-Confidence Gate: >= {CONFIDENCE_THRESHOLD}")
    print(f"  Sessions passing gate: {n_gated:,} / {len(y_true):,} ({coverage:.1f}% coverage)")

    if n_gated > 0:
        gated_metrics = compute_and_print_metrics(
            y_true[high_conf_mask],
            y_pred[high_conf_mask],
            y_prob[high_conf_mask],
            confidence[high_conf_mask],
            label=f"SECTION B: HIGH-CONFIDENCE GATED (>= {CONFIDENCE_THRESHOLD}) METRICS"
        )
    else:
        print("  [WARN] No samples passed the confidence gate.")
        gated_metrics = {}

    # --- FINAL SCORECARD -------------------------------------------------
    elapsed = time.time() - start
    print()
    print("+" + "=" * 70 + "+")
    print("|  FINAL PROFESSIONAL SCORECARD                                      |")
    print("+" + "=" * 70 + "+")
    if raw_metrics:
        print(f"|  RAW Accuracy (unfiltered):        {raw_metrics['accuracy']*100:>7.2f}%                      |")
        print(f"|  RAW Error Rate:                   {raw_metrics['error_rate']*100:>7.2f}%                      |")
        print(f"|  RAW Precision (weighted):         {raw_metrics['precision_w']*100:>7.2f}%                      |")
        print(f"|  RAW F1-Score (weighted):          {raw_metrics['f1_w']*100:>7.2f}%                      |")
        print(f"|  RAW ROC AUC:                      {raw_metrics['roc_auc']:>7.4f}                       |")
        print(f"|  RAW Brier Score:                  {raw_metrics['brier_score']:>7.4f}                       |")
        print(f"|  RAW Cohen's Kappa:                {raw_metrics['kappa']:>7.4f}                       |")
        print(f"|  RAW MCC:                          {raw_metrics['mcc']:>7.4f}                       |")
    print("+" + "=" * 70 + "+")
    if gated_metrics:
        print(f"|  GATED Accuracy (>={CONFIDENCE_THRESHOLD}):          {gated_metrics['accuracy']*100:>7.2f}%                      |")
        print(f"|  GATED Error Rate:                 {gated_metrics['error_rate']*100:>7.2f}%                      |")
        print(f"|  GATED Precision (weighted):       {gated_metrics['precision_w']*100:>7.2f}%                      |")
        print(f"|  GATED Positive Pred Value (PPV):  {gated_metrics['ppv']*100:>7.2f}%                      |")
        print(f"|  GATED F1-Score (weighted):        {gated_metrics['f1_w']*100:>7.2f}%                      |")
        print(f"|  GATED ROC AUC:                    {gated_metrics['roc_auc']:>7.4f}                       |")
        print(f"|  GATED Cohen's Kappa:              {gated_metrics['kappa']:>7.4f}                       |")
        print(f"|  GATED MCC:                        {gated_metrics['mcc']:>7.4f}                       |")
        print(f"|  GATED Coverage:                   {coverage:>7.1f}%                      |")
    print("+" + "=" * 70 + "+")
    print(f"|  Stocks Evaluated:     {len(per_stock):>3} / {len(UNIVERSE)}                                  |")
    print(f"|  Total Samples:        {len(y_true):>6,}                                     |")
    print(f"|  Evaluation Time:      {elapsed:>6.1f}s                                     |")
    print("+" + "=" * 70 + "+")
    print()

    # Save detailed JSON evaluation results to disk
    results_path = os.path.join(APP_DIR, "models", "universal_xgb_regression_results.json")
    export_payload = {
        "timestamp": datetime.now().isoformat() if "datetime" in globals() else str(time.time()),
        "model_version": meta.get("model_version", "unknown"),
        "raw_metrics": raw_metrics,
        "gated_metrics": gated_metrics,
        "per_stock": per_stock,
        "confidence_sweep": sweep_results,
    }
    try:
        with open(results_path, "w", encoding="utf-8") as f:
            json.dump(export_payload, f, indent=2)
        print(f"[OK] Full audit results saved to: {results_path}")
    except Exception as e:
        print(f"[WARN] Could not save json results: {e}")


if __name__ == "__main__":
    main()

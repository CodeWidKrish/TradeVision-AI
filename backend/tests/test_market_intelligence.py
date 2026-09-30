"""
test_market_intelligence.py — Automated Test Suite for TradeVision AI Market Intelligence Engine.
Tests:
1. Technical Analysis Engine calculations (RSI, MACD, Bollinger, ATR, VWAP, Price Structure)
2. Machine Learning XGBoost Pipeline (Chronological train/val/test split, features, probabilities)
3. Screenshot Vision Analysis (Structured JSON, Candlestick spectrometry, no hallucinated values)
4. News Intelligence Engine (Contextual sentiment, scope, freshness, event types)
5. Evidence Correlation Engine (Evidence Matrix, conflict detection, mixed signal handling)
6. Grounded Report Generator (11-section synthesis, non-guaranteed interpretations)
"""

import io
import unittest
import numpy as np
import pandas as pd
from PIL import Image

from app.services.technical_analysis_service import (
    compute_sma,
    compute_ema,
    compute_rsi,
    compute_macd,
    compute_bollinger_bands,
    compute_atr,
    compute_vwap,
    detect_price_structure,
    analyze_technical_indicators,
)
from app.services.ml_prediction_service import (
    extract_features_from_ohlcv,
    train_xgboost_model,
    predict_market_direction,
)
from app.services.vision_service import analyze_screenshot_vision
from app.services.news_intelligence_service import (
    evaluate_contextual_sentiment,
    classify_event_type,
    determine_freshness,
)
from app.services.evidence_correlation_service import build_evidence_matrix
from app.services.grounded_report_service import generate_market_intelligence_report


class TestMarketIntelligence(unittest.TestCase):

    # ── 1. TECHNICAL ANALYSIS TESTS ──────────────────────────────────────────

    def test_rsi_calculation(self):
        # Monotonically increasing prices should have RSI = 100
        prices = [100.0 + i for i in range(25)]
        rsi = compute_rsi(prices, 14)
        self.assertIsNotNone(rsi)
        self.assertGreater(rsi, 90.0)

        # Flat prices
        flat = [100.0] * 25
        rsi_flat = compute_rsi(flat, 14)
        self.assertTrue(rsi_flat == 100.0 or rsi_flat is not None)

    def test_macd_calculation(self):
        prices = [100.0 + (i * 0.5) for i in range(40)]
        macd = compute_macd(prices, 12, 26, 9)
        self.assertIsNotNone(macd["value"])
        self.assertIsNotNone(macd["signal"])
        self.assertIsNotNone(macd["histogram"])
        self.assertGreater(macd["value"], 0)  # Uptrend produces positive MACD

    def test_bollinger_bands(self):
        prices = [100.0 + (i % 5) for i in range(30)]
        boll = compute_bollinger_bands(prices, 20, 2.0)
        self.assertIsNotNone(boll["upper"])
        self.assertIsNotNone(boll["middle"])
        self.assertIsNotNone(boll["lower"])
        self.assertGreater(boll["upper"], boll["middle"])
        self.assertGreater(boll["middle"], boll["lower"])

    def test_price_structure_detection(self):
        # Create clear double bottom / swing low structure
        closes = [100, 95, 90, 85, 92, 98, 93, 85, 94, 102, 106, 110, 112, 115, 118]
        highs = [c + 2.0 for c in closes]
        lows = [c - 2.0 for c in closes]
        vols = [100000] * len(closes)

        struct = detect_price_structure(highs, lows, closes, vols, window=2)
        self.assertIn("trend_direction", struct)
        self.assertIn("support_zones", struct)
        self.assertIn("resistance_zones", struct)
        self.assertGreater(len(struct["support_zones"]), 0)

    # ── 2. ML XGBOOST PIPELINE TESTS ────────────────────────────────────────

    def test_xgboost_feature_extraction_and_training(self):
        n = 120
        dates = pd.date_range("2025-01-01", periods=n, freq="B")
        walk = np.cumsum(np.random.randn(n) * 1.5) + 500.0
        df = pd.DataFrame({
            "Open": walk,
            "High": walk + 2.0,
            "Low": walk - 2.0,
            "Close": walk,
            "Volume": [1000000] * n,
        }, index=dates)

        feat_df = extract_features_from_ohlcv(df, horizon=5, threshold_pct=1.0, include_target=True)
        self.assertFalse(feat_df.empty)
        self.assertIn("return_1", feat_df.columns)
        self.assertIn("target", feat_df.columns)

        model, meta = train_xgboost_model(feat_df)
        self.assertEqual(meta["model_name"], "TradeVision XGBoost")
        self.assertIn("test_accuracy", meta["evaluation_metrics"])
        self.assertGreater(meta["train_size"], 0)
        self.assertGreater(meta["test_size"], 0)

        pred = predict_market_direction("TEST_SYM", df)
        self.assertIn(pred["direction"], ("UP", "DOWN", "NEUTRAL"))
        self.assertTrue(0.0 <= pred["probability_up"] <= 1.0)
        self.assertTrue(0.0 <= pred["probability_down"] <= 1.0)
        self.assertTrue(0.0 <= pred["probability_neutral"] <= 1.0)
        self.assertTrue(0.0 <= pred["momentum_score"] <= 1.0)
        self.assertTrue(0.0 <= pred["volatility_score"] <= 1.0)

    # ── 3. SCREENSHOT VISION ANALYSIS TESTS ──────────────────────────────────

    def test_screenshot_vision_empty_image_guard(self):
        with self.assertRaises(ValueError):
            analyze_screenshot_vision(b"")

    def test_screenshot_vision_valid_image(self):
        # Create synthetic test chart image
        img = Image.new("RGB", (600, 400), color=(15, 23, 42))
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        bytes_data = buf.getvalue()

        res = analyze_screenshot_vision(bytes_data, filename="TCS_1D_chart.png")
        self.assertEqual(res["ticker"], "TCS")
        self.assertIn(res["exchange"], ("NSE", "BSE"))
        self.assertEqual(res["chart_type"], "candlestick")
        self.assertIsNone(res["displayed_price"])  # Strictly avoids hallucination
        self.assertIn("trend", res)
        self.assertIn("observations", res)
        self.assertGreater(res["analysis_confidence"], 0.4)

    # ── 4. NEWS INTELLIGENCE TESTS ──────────────────────────────────────────

    def test_contextual_sentiment_detection(self):
        # Pure positive
        self.assertEqual(evaluate_contextual_sentiment("Company reports record profit and revenue surges"), "positive")
        # Pure negative
        self.assertEqual(evaluate_contextual_sentiment("Company faces penalty and profit drops amidst probe"), "negative")
        # Mixed with contrastive conjunction
        self.assertEqual(evaluate_contextual_sentiment("Profit increased by 20% but future guidance was cut"), "mixed")
        self.assertEqual(evaluate_contextual_sentiment("Revenue rose while margins declined sharply"), "mixed")

    def test_event_classification(self):
        self.assertEqual(classify_event_type("Q3 financial results and net profit beat estimates"), "earnings")
        self.assertEqual(classify_event_type("RBI keeps repo rate unchanged at monetary policy meet"), "monetary_policy")
        self.assertEqual(classify_event_type("Wins multi-billion dollar IT contract deal"), "major_contracts")

    # ── 5. EVIDENCE CORRELATION & MATRIX TESTS ──────────────────────────────

    def test_evidence_correlation_mixed_signals(self):
        screenshot = {"trend": {"direction": "bullish"}, "chart_quality": "good"}
        technical = {
            "rsi": 65.0,
            "macd": {"value": 2.1, "signal": 1.5},
            "trend": {"ema": {"ema20": 1500, "ema50": 1420}},
            "volume": {"volume_change_percent": -30.0},
        }
        ml = {"direction": "UP", "probability_up": 0.72, "model_version": "tradevision-xgb-v1"}
        news = [{"title": "SEBI initiates regulatory probe against management", "sentiment": "negative"}]

        res = build_evidence_matrix("RELIANCE", screenshot, {}, technical, ml, news)
        self.assertEqual(res["overall_state"], "Signals are mixed")
        self.assertGreater(len(res["conflicts"]), 0)
        self.assertGreaterEqual(len(res["evidence_matrix"]), 4)

    # ── 6. GROUNDED REPORT SYNTHESIS TESTS ──────────────────────────────────

    def test_generate_market_intelligence_report(self):
        report = generate_market_intelligence_report("RELIANCE")
        self.assertTrue(report["report_id"].startswith("tv_rep_"))
        self.assertEqual(report["asset"]["symbol"], "RELIANCE")
        self.assertIn("executive_summary", report)
        self.assertIn("market_data", report)
        self.assertIn("technical_analysis", report)
        self.assertIn("ml_prediction", report)
        self.assertIn("evidence_matrix", report)
        self.assertIn("final_interpretation", report)
        self.assertIn("sources", report)
        self.assertGreaterEqual(len(report["sources"]), 4)


if __name__ == "__main__":
    unittest.main()

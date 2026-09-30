"""
evidence_correlation_service.py — Structured Evidence Correlation Engine for TradeVision AI.
Conforms strictly to Sections 19, 20, and 21 of the Master Specification.
Correlates:
- Screenshot vision observation
- Real calculated technical indicators
- Live market data & price action
- Volume dynamics
- XGBoost machine learning probabilities
- Verified recent news & macro events
Constructs the auditable Evidence Matrix:
| Source | Finding | Direction | Strength | Timestamp | Evidence ID |
Detects conflicts explicitly (e.g. Bullish technicals vs. Negative fundamental news).
NEVER averages fake confidence scores. Signals when evidence is mixed.
"""

import time
from datetime import datetime
from typing import Dict, Any, List, Optional


def build_evidence_matrix(
    symbol: str,
    screenshot_analysis: Optional[Dict[str, Any]],
    live_market_data: Optional[Dict[str, Any]],
    technical_analysis: Optional[Dict[str, Any]],
    ml_prediction: Optional[Dict[str, Any]],
    news_intelligence: Optional[List[Dict[str, Any]]],
    macro_context: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Constructs the structured Evidence Matrix and identifies confluence or conflict
    across all disparate market intelligence streams.
    """
    matrix: List[Dict[str, Any]] = []
    now_str = datetime.now().strftime("%d %b %Y, %H:%M:%S IST")

    # 1. SCREENSHOT OBSERVATION EVIDENCE
    if screenshot_analysis:
        trend = screenshot_analysis.get("trend", {})
        dir_val = trend.get("direction", "neutral").capitalize()
        direction = "Positive" if dir_val == "Bullish" else ("Negative" if dir_val == "Bearish" else "Neutral")
        patterns = screenshot_analysis.get("patterns", [])
        pattern_str = ", ".join(patterns) if patterns else "Visual chart pattern"

        finding = f"{pattern_str} ({trend.get('direction', 'neutral')} trajectory)"
        matrix.append({
            "source": "Screenshot",
            "finding": finding,
            "direction": direction,
            "strength": "Medium" if screenshot_analysis.get("chart_quality") == "good" else "Low",
            "timestamp": "Upload time",
            "evidence_id": "screen_vision_001",
            "claim": f"Screenshot observation indicates {finding.lower()}.",
        })

    # 2. TECHNICAL INDICATORS EVIDENCE
    if technical_analysis:
        rsi = technical_analysis.get("rsi")
        macd = technical_analysis.get("macd", {})
        macd_val = macd.get("value")
        macd_sig = macd.get("signal")
        trend_info = technical_analysis.get("trend", {})
        ema = trend_info.get("ema", {})
        ema20 = ema.get("ema20")
        ema50 = ema.get("ema50")

        # RSI Finding
        if rsi is not None:
            if rsi < 35:
                rsi_dir = "Positive"
                rsi_finding = f"RSI oversold ({rsi:.1f}) in potential value accumulation zone"
            elif rsi > 70:
                rsi_dir = "Negative"
                rsi_finding = f"RSI overbought ({rsi:.1f}) indicating upside exhaustion risk"
            elif rsi >= 50:
                rsi_dir = "Positive"
                rsi_finding = f"RSI at {rsi:.1f} holding positive momentum above centerline"
            else:
                rsi_dir = "Negative"
                rsi_finding = f"RSI at {rsi:.1f} trading below centerline"

            matrix.append({
                "source": "Technical",
                "finding": rsi_finding,
                "direction": rsi_dir,
                "strength": "Medium",
                "timestamp": "Live",
                "evidence_id": "tech_rsi_001",
                "claim": f"RSI calculation confirms {rsi_finding.lower()}.",
            })

        # Moving Average / MACD Finding
        if ema20 and ema50:
            ma_aligned = ema20 > ema50
            matrix.append({
                "source": "Technical",
                "finding": f"EMA20 (₹{ema20:,.2f}) {'>' if ma_aligned else '<'} EMA50 (₹{ema50:,.2f})",
                "direction": "Positive" if ma_aligned else "Negative",
                "strength": "Medium",
                "timestamp": "Live",
                "evidence_id": "tech_ema_001",
                "claim": f"Moving averages are { 'bullishly aligned' if ma_aligned else 'bearishly aligned' }.",
            })

    # 3. VOLUME DYNAMICS EVIDENCE
    if technical_analysis and "volume" in technical_analysis:
        vol_info = technical_analysis["volume"]
        vol_change = vol_info.get("volume_change_percent", 0.0)
        curr_vol = vol_info.get("current_volume", 0)
        avg_vol = vol_info.get("average_volume", 0)

        if vol_change > 15.0:
            vol_dir = "Positive"
            vol_finding = f"Volume surge: {vol_change:+.1f}% above 20-day average"
            vol_str = "High" if vol_change > 40.0 else "Medium"
        elif vol_change < -20.0:
            vol_dir = "Negative"
            vol_finding = f"Subdued volume: {vol_change:.1f}% below 20-day average"
            vol_str = "Low"
        else:
            vol_dir = "Neutral"
            vol_finding = f"Volume tracking normal baseline ({vol_change:+.1f}%)"
            vol_str = "Medium"

        matrix.append({
            "source": "Volume",
            "finding": vol_finding,
            "direction": vol_dir,
            "strength": vol_str,
            "timestamp": "Live",
            "evidence_id": "vol_surge_001",
            "claim": f"Volume inspection records {vol_finding.lower()}.",
        })

    # 4. ML MODEL EVIDENCE (XGBoost tradevision-xgb-v1)
    if ml_prediction:
        ml_dir = ml_prediction.get("direction", "NEUTRAL")
        prob_up = ml_prediction.get("probability_up", 0.33)
        prob_down = ml_prediction.get("probability_down", 0.33)
        winning_prob = prob_up if ml_dir == "UP" else (prob_down if ml_dir == "DOWN" else ml_prediction.get("probability_neutral", 0.34))

        matrix.append({
            "source": "ML",
            "finding": f"{ml_dir} probability {winning_prob * 100.0:.1f}% ({ml_prediction.get('model_version', 'XGBoost')})",
            "direction": "Positive" if ml_dir == "UP" else ("Negative" if ml_dir == "DOWN" else "Neutral"),
            "strength": "Model-based",
            "timestamp": "Live",
            "evidence_id": "ml_xgb_001",
            "claim": f"XGBoost model assigns {winning_prob * 100.0:.1f}% probability to the {ml_dir} class.",
        })

    # 5. NEWS INTELLIGENCE EVIDENCE
    if news_intelligence:
        for idx, article in enumerate(news_intelligence[:3]):
            sent = article.get("sentiment", "neutral")
            direction = "Positive" if sent == "positive" else ("Negative" if sent == "negative" else "Neutral")
            event_type = article.get("event_type", "market_action").replace("_", " ").capitalize()
            impact = article.get("impact", "medium").capitalize()
            title_trunc = article.get("title", "")
            if len(title_trunc) > 55:
                title_trunc = title_trunc[:52] + "..."

            matrix.append({
                "source": "News",
                "finding": f"{event_type}: {title_trunc}",
                "direction": direction,
                "strength": impact,
                "timestamp": article.get("published_at", "Recent"),
                "evidence_id": f"news_item_{idx + 1:03d}",
                "claim": f"Verified press reported: '{article.get('title')}' with {sent} sentiment.",
            })

    # 6. MACRO BENCHMARKS
    if macro_context:
        bias = macro_context.get("bias", "Stable Market")
        macro_dir = "Positive" if "Bullish" in bias else ("Negative" if "Bearish" in bias else "Neutral")
        matrix.append({
            "source": "Market Context",
            "finding": f"Broad Indian indices exhibit {bias.lower()}",
            "direction": macro_dir,
            "strength": "Medium",
            "timestamp": "Live",
            "evidence_id": "macro_index_001",
            "claim": f"Macro benchmarks reflect {bias.lower()}.",
        })

    # ── CONFLICT DETECTION & CROSS-SOURCE ANALYSIS ──────────────────────
    pos_count = sum(1 for m in matrix if m["direction"] == "Positive")
    neg_count = sum(1 for m in matrix if m["direction"] == "Negative")
    neutral_count = sum(1 for m in matrix if m["direction"] == "Neutral")

    # Inspect specific cross-source conflicts
    conflicts: List[str] = []
    agreements: List[str] = []

    # Check Technical vs News conflict
    tech_pos = any(m["source"] == "Technical" and m["direction"] == "Positive" for m in matrix)
    tech_neg = any(m["source"] == "Technical" and m["direction"] == "Negative" for m in matrix)
    news_neg = any(m["source"] == "News" and m["direction"] == "Negative" for m in matrix)
    news_pos = any(m["source"] == "News" and m["direction"] == "Positive" for m in matrix)

    if tech_pos and news_neg:
        conflicts.append("Technical indicators display bullish momentum, while recent external news introduces negative fundamental headwinds.")
    elif tech_neg and news_pos:
        conflicts.append("Technical indicators reflect price weakness, while verified news reports positive developments.")

    # Check ML vs Technical agreement
    ml_pos = any(m["source"] == "ML" and m["direction"] == "Positive" for m in matrix)
    ml_neg = any(m["source"] == "ML" and m["direction"] == "Negative" for m in matrix)

    if tech_pos and ml_pos:
        agreements.append("Technical trend indicators and the TradeVision XGBoost forward prediction both align positively.")
    elif tech_neg and ml_neg:
        agreements.append("Technical trend indicators and the TradeVision XGBoost forward prediction both align negatively.")
    elif (tech_pos and ml_neg) or (tech_neg and ml_pos):
        conflicts.append("XGBoost mathematical prediction diverges from current technical indicator positioning.")

    # Check Volume confirmation
    vol_pos = any(m["source"] == "Volume" and m["direction"] == "Positive" for m in matrix)
    if (tech_pos or ml_pos) and vol_pos:
        agreements.append("Above-average volume confirms price expansion.")
    elif (tech_pos or ml_pos) and not vol_pos:
        conflicts.append("Upward price action lacks robust volume expansion, warranting caution against false breakouts.")

    # Overall Evidence State: Confluent vs Mixed
    if pos_count > 0 and neg_count > 0:
        overall_state = "Signals are mixed"
        summary_verdict = "EVIDENCE CONFLICT / NEUTRAL ACCUMULATION"
    elif pos_count >= 3 and neg_count == 0:
        overall_state = "Bullish confluence across majority streams"
        summary_verdict = "BULLISH CONFLUENCE"
    elif neg_count >= 3 and pos_count == 0:
        overall_state = "Bearish confluence across majority streams"
        summary_verdict = "BEARISH DRAG"
    else:
        overall_state = "Balanced market conditions with moderate conviction"
        summary_verdict = "NEUTRAL / BALANCED"

    return {
        "overall_state": overall_state,
        "summary_verdict": summary_verdict,
        "positive_signals_count": pos_count,
        "negative_signals_count": neg_count,
        "neutral_signals_count": neutral_count,
        "agreements": agreements,
        "conflicts": conflicts,
        "evidence_matrix": matrix,
        "evaluated_at": now_str,
    }

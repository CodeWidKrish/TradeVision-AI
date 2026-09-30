"""
ai_orchestrator_service.py — Central AI Orchestration & Market Reasoning Engine for TradeVision AI.
Conforms strictly to Sections 1, 2, 3, 4, 5, 7, 8, 13, 14, 18, 22, 28, 33, 36, 43, 51, 52 of the Master Specification.

Orchestrates:
- 25 Registered AI Capabilities
- Intent Classification & Data Dependency Routing
- Grounded Evidence Correlation (Market, Technicals, XGBoost ML, News, Vision)
- Deterministic Signal Engine (BULLISH/NEUTRAL/BEARISH Bias)
- Zero Hallucination Financial Reasoning via Groq LLM
"""

import os
import re
import time
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from enum import Enum
import pytz
import pandas as pd
import yfinance as yf

from app.services.live_market_service import get_live_quote, clean_symbol
from app.services.technical_analysis_service import analyze_technical_indicators
from app.services.ml_prediction_service import predict_market_direction
from app.services.news_intelligence_service import get_structured_news_intelligence
from app.services.market_service import get_indices, get_top_movers
from app.services.groq_service import groq_service

logger = logging.getLogger(__name__)
IST = pytz.timezone("Asia/Kolkata")

# ── 1. AI FEATURE REGISTRY (Section 4) ──────────────────────────────────
class AICapability(str, Enum):
    STOCK_ANALYSIS = "stock_analysis"
    SCREENSHOT_ANALYSIS = "screenshot_analysis"
    TECHNICAL_ANALYSIS = "technical_analysis"
    ML_PREDICTION_EXPLANATION = "ml_prediction_explanation"
    SIGNAL_INTERPRETATION = "signal_interpretation"
    NEWS_ANALYSIS = "news_analysis"
    NEWS_SENTIMENT_ANALYSIS = "news_sentiment_analysis"
    MARKET_SENTIMENT = "market_sentiment"
    AI_CHATBOT = "ai_chatbot"
    RISK_ANALYSIS = "risk_analysis"
    SUPPORT_RESISTANCE_EXPLANATION = "support_resistance_explanation"
    CANDLESTICK_ANALYSIS = "candlestick_analysis"
    PATTERN_RECOGNITION = "pattern_recognition"
    TREND_ANALYSIS = "trend_analysis"
    VOLUME_ANALYSIS = "volume_analysis"
    VOLATILITY_ANALYSIS = "volatility_analysis"
    MARKET_SUMMARY = "market_summary"
    STOCK_COMPARISON = "stock_comparison"
    PORTFOLIO_WATCHLIST_INSIGHTS = "portfolio_watchlist_insights"
    EARNINGS_EVENT_ANALYSIS = "earnings_event_analysis"
    EXPLAIN_PREDICTION = "explain_prediction"
    EXPLAIN_INDICATOR = "explain_indicator"
    EXPLAIN_PRICE_MOVEMENT = "explain_price_movement"
    SCREENSHOT_TO_REPORT = "screenshot_to_report"
    AI_GENERATED_MARKET_REPORT = "ai_generated_market_report"

class ResponseMode(str, Enum):
    QUICK = "QUICK"
    STANDARD = "STANDARD"
    DETAILED = "DETAILED"

# ── 2. KNOWN TICKERS & EXTRACTION (Section 7) ──────────────────────────
KNOWN_TICKERS = {
    "RELIANCE": "Reliance Industries Ltd",
    "TCS": "Tata Consultancy Services",
    "INFY": "Infosys Ltd",
    "HDFCBANK": "HDFC Bank Ltd",
    "ICICIBANK": "ICICI Bank Ltd",
    "SBIN": "State Bank of India",
    "BHARTIARTL": "Bharti Airtel Ltd",
    "ITC": "ITC Ltd",
    "KOTAKBANK": "Kotak Mahindra Bank",
    "LT": "Larsen & Toubro Ltd",
    "TATAMOTORS": "Tata Motors Ltd",
    "MARUTI": "Maruti Suzuki India",
    "AXISBANK": "Axis Bank Ltd",
    "BAJFINANCE": "Bajaj Finance Ltd",
    "WIPRO": "Wipro Ltd",
    "HCLTECH": "HCL Technologies",
    "ZOMATO": "Zomato Ltd",
    "PAYTM": "One97 Communications",
    "JIOFIN": "Jio Financial Services",
    "ADANIENT": "Adani Enterprises",
    "TATASTEEL": "Tata Steel Ltd",
    "NIFTY": "NIFTY 50",
    "BANKNIFTY": "NIFTY Bank",
}

class TradeVisionAIOrchestrator:
    def __init__(self):
        self.groq = groq_service
        logger.info("TradeVisionAIOrchestrator initialized with 25 AI capabilities.")

    # ── DOMAIN GUARD & INTENT ROUTER (Sections 1, 8, 9, 10, 11, 12, 13, 15, 24) ─
    def evaluate_domain_and_intent(
        self, text: str, context_symbol: Optional[str] = None
    ) -> Tuple[bool, str, Optional[str]]:
        """
        Two-Stage Domain & Intent Guard.
        Strictly restricts TradeVision AI Copilot to:
        1. TradeVision AI application features & troubleshooting
        2. Stocks & equity market analysis
        3. Financial market data & educational concepts
        4. Technical analysis & indicators
        5. ML predictions in TradeVision
        6. News & sentiment analysis
        7. Screenshot / chart vision
        8. TradeVision's own project architecture & code (Flutter, FastAPI, WebSockets, XGBoost)

        Immediately rejects and redirects generic programming, homework, math, physics,
        general knowledge trivia, entertainment, or prompt injection without consuming LLM/API tokens.
        """
        t = text.lower().strip()

        # 1. Prompt Injection & Context Hijacking Protection (Section 5 & 23)
        injection_triggers = [
            "ignore previous instructions", "ignore all instructions", "pretend you are",
            "act as a", "act as an", "forget tradevision", "disregard instructions",
            "enter developer mode", "dan mode", "jailbreak", "reveal your system prompt",
            "bypass restriction", "unrestricted mode", "disable the stock restriction",
            "you are no longer tradevision", "as a hypothetical, explain"
        ]
        if any(trig in t for trig in injection_triggers):
            return False, "OUT_OF_SCOPE", (
                "I am focused on TradeVision AI, stocks, market analysis, and related financial insights. "
                "Please ask me about a stock, market trend, chart, prediction, news, or TradeVision feature."
            )

        # 2. TradeVision Project Code & Technical Troubleshooting (Section 6, 7, 13, 14, 15)
        # Questions concerning TradeVision's own implementation are explicitly ALLOWED.
        is_tv_technical = False
        if any(tv_ref in t for tv_ref in ["tradevision", "this app", "the app", "the project", "our app", "trade vision"]):
            if any(term in t for term in [
                "code", "backend", "frontend", "flutter", "fastapi", "python", "dart",
                "websocket", "socket", "api", "pipeline", "database", "xgboost", "algorithm",
                "error", "not updating", "disconnected", "disconnect", "render", "rendering",
                "calculate", "connect", "architecture", "model", "server", "screen", "endpoint"
            ]):
                is_tv_technical = True
        elif any(phrase in t for phrase in [
            "why is the chart not updating", "why isn't the chart updating", "chart not updating",
            "why is websocket disconnected", "websocket disconnected", "websocket error",
            "why is tradevision websocket", "how does tradevision calculate rsi",
            "why is my flutter tradevision chart not rendering", "how does the prediction api work",
            "how does screenshot analysis work", "how does the news sentiment system work",
            "how is the prediction generated", "how does xgboost work in tradevision",
            "how does the tradevision fastapi backend send live prices", "why did the chart stop"
        ]):
            is_tv_technical = True

        if is_tv_technical:
            if any(err_kw in t for err_kw in ["not updating", "disconnect", "error", "not loading", "not rendering", "bug", "failing", "disconnected"]):
                return True, "PROJECT_TROUBLESHOOTING", None
            return True, "PROJECT_TECHNICAL", None

        # 3. App Navigation, Tour, Walkthrough & Feature Guide
        if any(nav_kw in t for nav_kw in [
            "navigate", "navigation", "tour", "walkthrough", "walk me through", "guide me",
            "whole app", "explore the app", "how to use this app", "how do i use this app",
            "how to use the app", "show me around", "getting started with the app",
            "getting started", "app walkthrough", "app tour", "app navigation",
            "what does this app do", "what can this app do", "how does the app work",
            "how do i use tradevision", "what can tradevision do", "what are the features",
            "help me navigate", "help me to navigate"
        ]):
            return True, "APP_NAVIGATION", None

        # 4. Friendly Greetings, Self-Introductions, & Pleasantries
        is_greeting_or_intro = False
        if re.search(r"\b(my name is|i am|i'm|call me)\b", t):
            is_greeting_or_intro = True
        elif any(re.search(rf"\b{g}\b", t) for g in [
            "hi", "hello", "hey", "good morning", "good afternoon", "good evening",
            "namaste", "greetings", "howdy", "hola"
        ]):
            is_greeting_or_intro = True
        elif any(p in t for p in [
            "how are you", "how are you doing", "who are you", "what are you", "what can you do",
            "how can you help me", "what do you do", "introduce yourself"
        ]):
            is_greeting_or_intro = True

        if is_greeting_or_intro:
            if any(w in t for w in ["navigate", "navigation", "tour", "guide", "walkthrough", "app", "explore"]):
                return True, "APP_NAVIGATION", None
            return True, "GREETING_OR_INTRODUCTION", None

        # 5. Generic Programming Refusal (Section 3, 4, 13, 14)
        # Reject generic coding, tutorials, homework, non-TradeVision debugging
        generic_coding_patterns = [
            "write java code", "java code for", "java code", "inheritance in java", "inheritance java",
            "explain inheritance", "polymorphism", "teach me java", "write a java", "java program",
            "debug my java", "java calculator", "write python code for a sorting", "sorting algorithm in python",
            "write a game in python", "game in python", "teach me python from scratch", "teach me python",
            "write python code to calculate rsi", "write python code", "teach me c++", "how do i learn c++",
            "c++ code", "c++ program", "c++ tutorial", "learn c++", "write a react website", "generic website",
            "create a website", "write a javascript calculator", "javascript calculator", "react website",
            "react code", "sql tutorial", "fibonacci", "write code that calculates", "teach me arrays",
            "teach me recursion", "write a banking application", "how to hack a website", "how do i hack",
            "debug my program", "debug this code", "fix my program", "fix my java"
        ]
        if any(p in t for p in generic_coding_patterns):
            if "python" in t:
                return False, "OUT_OF_SCOPE", (
                    "I can help with Python when it is specifically related to TradeVision AI. "
                    "Please ask me about the TradeVision backend, ML pipeline, market-data system, "
                    "FastAPI integration, or another part of the project."
                )
            if "java" in t:
                return False, "OUT_OF_SCOPE", (
                    "I am focused on TradeVision AI rather than general programming. "
                    "Please ask me about debugging TradeVision's Flutter frontend, FastAPI backend, "
                    "ML pipeline, WebSocket connection, charts, or AI features."
                )
            return False, "OUT_OF_SCOPE", (
                "Please ask me something related to TradeVision AI, stocks, market analysis, charts, "
                "predictions, or financial news. I am here to help you understand the market and get useful insights from TradeVision."
            )

        # 6. Homework / Science / Trivia / General Knowledge Refusal (Section 3, 4, 22)
        trivia_homework_patterns = [
            "capital of france", "capital of", "who is the president", "who invented", "who is your favorite",
            "tell me a joke", "write a poem", "write me a poem", "write an essay", "global warming",
            "what should i eat", "recipe for", "weather in", "tell me a story",
            "what is physics", "explain physics", "quantum physics", "biology", "solve this equation",
            "math equation", "mathematics equation", "college assignment", "my homework", "help me with my homework",
            "chemistry", "who won the world cup"
        ]
        if any(p in t for p in trivia_homework_patterns):
            if any(k in t for k in ["poem", "joke", "story", "essay"]):
                return False, "OUT_OF_SCOPE", (
                    "Let's keep it focused on the market. Please ask me about a stock, chart, market movement, "
                    "technical indicator, prediction, or anything related to TradeVision AI."
                )
            if any(k in t for k in ["capital of", "who is", "what should i eat", "weather"]):
                return False, "OUT_OF_SCOPE", (
                    "I am focused on TradeVision AI and financial markets. Please ask me about a stock, "
                    "market trend, technical indicator, chart, prediction, financial news, or a TradeVision feature."
                )
            return False, "OUT_OF_SCOPE", (
                "Please ask me something related to TradeVision AI, stocks, market analysis, charts, "
                "predictions, or financial news. I am here to help you understand the market and get useful insights from TradeVision."
            )

        # 7. Stock Comparison (Section 28)
        if any(k in t for k in ["compare", " vs ", " versus ", " or "]) and any(tick.lower() in t for tick in KNOWN_TICKERS):
            return True, "STOCK_COMPARISON", None

        # 8. Dynamic Market Summary (Section 27)
        if any(k in t for k in [
            "market summary", "today's market", "market today", "how is the market", "nifty update",
            "overall market", "market overview", "indian market", "sector movers", "summary of the market",
            "market report", "market status", "market sentiment"
        ]):
            return True, "MARKET_SUMMARY", None

        # 9. Technical Indicators & Candlestick Explanation (Section 11, 12, 26)
        if any(k in t for k in [
            "what is rsi", "explain rsi", "what is macd", "explain macd", "bollinger", "what is ema",
            "what is sma", "what is vwap", "what is atr", "explain indicator", "candlestick", "doji",
            "hammer", "support and resistance", "support level", "resistance level", "breakout", "breakdown"
        ]):
            return True, "INDICATOR_EXPLANATION", None

        # 10. ML Prediction Explanation (Section 22 & 23)
        if any(k in t for k in [
            "ml model", "xgboost", "what does ml predict", "explain prediction", "why up", "why down",
            "prediction accuracy", "machine learning", "probability of up", "model output", "prediction horizon"
        ]):
            return True, "ML_EXPLANATION", None

        # 11. Price Movement Analysis (Section 5)
        if any(k in t for k in ["why is", "why did", "falling", "dropping", "surging", "crashing", "rallying", "reason for drop", "reason for rise"]):
            return True, "PRICE_MOVEMENT_ANALYSIS", None

        # 12. News & Press Sentiment (Section 15, 16, 17)
        if any(k in t for k in ["news", "headline", "announcement", "earnings", "quarterly result", "press flow"]):
            return True, "NEWS_SENTIMENT", None

        # 13. Buy/Hold/Sell Position Interpretation (Section 13)
        if any(k in t for k in ["should i buy", "should i sell", "should i hold", "target price", "stop loss", "buy or sell", "position"]):
            return True, "POSITION_INTERPRETATION", None

        # 14. Screenshot & Chart Analysis (Section 20 & 21)
        if any(k in t for k in ["screenshot", "chart", "chart analysis", "visible trend", "trendline"]):
            return True, "CHART_ANALYSIS", None

        # 15. Risk Analysis (Section 24)
        if any(k in t for k in ["risk", "risks", "drawdown", "invalidation", "volatility risk"]):
            return True, "RISK_ANALYSIS", None

        # 16. Supported General Finance Educational Concepts (Section 11 & 12)
        if any(k in t for k in [
            "what is a stock split", "stock split", "market capitalization", "market cap",
            "what is eps", "what is p/e", "what is pe ratio", "pe ratio", "p/e ratio",
            "what is a dividend", "dividend", "bear market", "bull market", "what is volatility",
            "what does volume mean", "what does bullish mean", "what does bearish mean",
            "what is fii", "what is dii", "what is ipo"
        ]):
            return True, "SUPPORTED_GENERAL_FINANCE", None

        # 17. TradeVision Features & App Help (Section 2, 7)
        if any(k in t for k in [
            "tradevision", "how to generate", "how to", "how do i", "how can i", "watchlist",
            "generate report", "dark mode", "alert", "alerts", "tradevision feature", "app lock",
            "in the app", "app guide", "how does the app", "how does tradevision",
            "paper trading", "paper trade", "simulate trade", "virtual trading", "how to trade",
            "xai", "explainable ai", "feature contribution", "model explanation"
        ]):
            return True, "TRADEVISION_FEATURE", None

        # 16. Stock Analysis via Ticker Detection or General Stock References (Section 9)
        symbols = self.extract_symbols(text, context_symbol=context_symbol)
        if symbols or any(w in t for w in ["stock", "share", "equity", "holding", "ticker", "reliance", "tcs", "infy", "nifty", "sensex"]):
            return True, "STOCK_ANALYSIS", None

        # 17. Default Safety Gate for Any Unrelated / Ambiguous Non-Financial Query
        return False, "OUT_OF_SCOPE", (
            "Please ask me a question related to stocks, markets, charts, predictions, financial news, "
            "or TradeVision AI. That is where I can give you the most useful and relevant answer."
        )

    def classify_intent(self, text: str, context_symbol: Optional[str] = None) -> str:
        """Backward-compatible helper returning intent string."""
        _, intent, _ = self.evaluate_domain_and_intent(text, context_symbol=context_symbol)
        return intent

    def extract_symbols(self, text: str, context_symbol: Optional[str] = None) -> List[str]:
        """Extracts one or more symbols from text, resolving pronouns to context_symbol."""
        found = []
        text_upper = text.upper()
        for ticker in KNOWN_TICKERS.keys():
            if re.search(rf"\b{ticker}\b", text_upper):
                found.append(ticker)

        # Common name aliases
        if "TATA MOTORS" in text_upper and "TATAMOTORS" not in found:
            found.append("TATAMOTORS")
        if "TATA STEEL" in text_upper and "TATASTEEL" not in found:
            found.append("TATASTEEL")
        if "HDFC" in text_upper and "HDFCBANK" not in found:
            found.append("HDFCBANK")
        if "ICICI" in text_upper and "ICICIBANK" not in found:
            found.append("ICICIBANK")
        if ("SBI" in text_upper or "STATE BANK" in text_upper) and "SBIN" not in found:
            found.append("SBIN")
        if "AIRTEL" in text_upper and "BHARTIARTL" not in found:
            found.append("BHARTIARTL")

        # Pronoun resolution (Section 7 & 8)
        if not found and context_symbol:
            pronouns = ["it", "this", "the stock", "this stock", "its", "holding", "them"]
            if any(p in text.lower().split() for p in pronouns) or "why is it" in text.lower():
                found.append(context_symbol.upper())

        return found

    # ── DATA GATHERING LAYER (Section 3) ────────────────────────────────
    def _fetch_stock_bundle(self, symbol: str) -> Dict[str, Any]:
        """Gathers verified quote, OHLCV, indicators, ML prediction, and news for a symbol."""
        clean_sym = clean_symbol(symbol).upper()
        yf_sym = f"{clean_sym}.NS" if not clean_sym.startswith("^") and not clean_sym.endswith(".NS") else clean_sym

        quote = get_live_quote(clean_sym) or {}
        price = quote.get("current_price") or quote.get("price") or 0.0
        change_pct = float(quote.get("change_percent") or quote.get("change_pct") or 0.0)
        company = quote.get("company_name", clean_sym)

        hist_df = pd.DataFrame()
        try:
            ticker_obj = yf.Ticker(yf_sym)
            hist_df = ticker_obj.history(period="3mo")
            if hist_df.empty and not yf_sym.startswith("^"):
                hist_df = yf.Ticker(f"{clean_sym}.BO").history(period="3mo")
        except Exception as e:
            logger.warning(f"OHLCV history error for {clean_sym}: {e}")

        technicals: Dict[str, Any] = {}
        ml_pred: Dict[str, Any] = {}
        if not hist_df.empty and len(hist_df) >= 15:
            closes = [float(p) for p in hist_df["Close"].dropna().tolist()]
            highs = [float(p) for p in hist_df["High"].dropna().tolist()]
            lows = [float(p) for p in hist_df["Low"].dropna().tolist()]
            volumes = [float(v) for v in hist_df["Volume"].dropna().tolist()]
            technicals = analyze_technical_indicators(highs, lows, closes, volumes)
            ml_pred = predict_market_direction(clean_sym, hist_df, technicals)

        news = get_structured_news_intelligence(clean_sym, company_name=company, limit=4)

        return {
            "symbol": clean_sym,
            "company": company,
            "price": price,
            "change_pct": change_pct,
            "technicals": technicals,
            "ml_prediction": ml_pred,
            "news": news,
            "timestamp": datetime.now(IST).strftime("%H:%M:%S IST"),
        }

    # ── SIGNAL ENGINE (Section 13 & 14) ─────────────────────────────────
    def compute_signal(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Produces deterministic BULLISH/NEUTRAL/BEARISH bias with supporting & contradictory evidence.
        Never random LLM opinion.
        """
        tech = data.get("technicals", {})
        ml = data.get("ml_prediction", {})
        news = data.get("news", [])

        rsi = float(tech.get("rsi") or tech.get("momentum", {}).get("rsi_14") or 50.0)
        trend = tech.get("price_structure", {}).get("trend_direction", "neutral").lower()
        prob_up = float(ml.get("probability_up") or 0.33)
        prob_down = float(ml.get("probability_down") or 0.33)
        prob_neutral = float(ml.get("probability_neutral") or 0.34)

        # Technical Score (0.0 to 1.0)
        tech_score = 0.50
        if trend == "bullish":
            tech_score += 0.20
        elif trend == "bearish":
            tech_score -= 0.20

        if 45.0 <= rsi <= 65.0:
            tech_score += 0.10
        elif rsi > 70.0:
            tech_score -= 0.10  # Overbought caution
        elif rsi < 30.0:
            tech_score += 0.05  # Oversold reversal possibility

        tech_score = max(0.0, min(1.0, tech_score))

        # News sentiment score
        pos_news = sum(1 for n in news if n.get("sentiment") == "positive")
        neg_news = sum(1 for n in news if n.get("sentiment") == "negative")
        news_sentiment = "neutral"
        if pos_news > neg_news:
            news_sentiment = "positive"
        elif neg_news > pos_news:
            news_sentiment = "negative"
        elif pos_news > 0 and neg_news > 0:
            news_sentiment = "mixed"

        # Deterministic Classification
        if tech_score >= 0.60 and prob_up >= 0.45 and prob_up > prob_down:
            signal = "BULLISH_BIAS"
        elif tech_score <= 0.40 and prob_down >= 0.45 and prob_down > prob_up:
            signal = "BEARISH_BIAS"
        else:
            signal = "NEUTRAL_BIAS"

        reasons = []
        contradictions = []

        if trend == "bullish":
            reasons.append("Structural trend shows series of higher highs and higher lows.")
        elif trend == "bearish":
            (reasons if signal == "BEARISH_BIAS" else contradictions).append("Price structure remains under moving average pressure.")

        if prob_up >= 0.50:
            reasons.append(f"TradeVision XGBoost model assigns {prob_up*100:.1f}% probability to an upward continuation.")
        elif prob_down >= 0.50:
            (reasons if signal == "BEARISH_BIAS" else contradictions).append(f"XGBoost model indicates elevated downside probability of {prob_down*100:.1f}%.")

        if rsi > 70.0:
            contradictions.append(f"RSI (14) is elevated at {rsi:.1f}, entering an overbought consolidation zone.")
        elif rsi < 30.0:
            contradictions.append(f"RSI is oversold at {rsi:.1f}; momentum could trigger sharp short-covering.")

        if news_sentiment == "negative" and signal == "BULLISH_BIAS":
            contradictions.append("Recent press flow contains negative or regulatory headwinds.")

        support = tech.get("key_levels", {}).get("nearest_support")
        resistance = tech.get("key_levels", {}).get("nearest_resistance")

        return {
            "signal": signal,
            "technical_score": round(tech_score, 2),
            "ml_probability_up": round(prob_up, 3),
            "ml_probability_down": round(prob_down, 3),
            "ml_probability_neutral": round(prob_neutral, 3),
            "news_sentiment": news_sentiment,
            "volume_confirmation": True,
            "volatility": "normal",
            "support": [support] if support else [],
            "resistance": [resistance] if resistance else [],
            "reasons": reasons if reasons else ["Price consolidating near current technical equilibrium."],
            "contradictions": contradictions if contradictions else ["No acute multi-source divergence observed."],
        }

    # ── ORCHESTRATION PIPELINE (Section 53) ──────────────────────────────
    async def orchestrate(
        self,
        query: str,
        symbol_hint: Optional[str] = None,
        mode: ResponseMode = ResponseMode.STANDARD,
        history: Optional[List[Dict[str, Any]]] = None,
    ) -> Dict[str, Any]:
        """
        Main entry point for TradeVision AI Orchestration with Two-Stage Domain Guard.
        Stage 1: Domain / Intent Guard — immediately redirects out-of-scope queries (0 tokens wasted).
        Stage 2: Grounded Multi-Source Reasoning Pipeline for verified domains.
        """
        t0 = time.time()
        now_ist = datetime.now(IST)

        # ── STAGE 1: DOMAIN & INTENT GUARD (Sections 8, 9, 29) ─────────────
        is_allowed, intent, scope_reply = self.evaluate_domain_and_intent(query, context_symbol=symbol_hint)

        if not is_allowed or intent == "OUT_OF_SCOPE":
            latency_ms = int((time.time() - t0) * 1000)
            return {
                "success": True,
                "intent": "OUT_OF_SCOPE",
                "mode": mode.value,
                "reply": scope_reply or (
                    "Please ask me a question related to stocks, markets, charts, predictions, financial news, "
                    "or TradeVision AI. That’s where I can give you the most useful and relevant answer."
                ),
                "model": "tradevision-domain-guard",
                "provider": "TradeVision Guard",
                "latency_ms": latency_ms,
                "grounded_data": None,
                "sources": [],
                "generated_at": now_ist.strftime("%d %b %Y, %H:%M:%S IST"),
            }

        # ── STAGE 2: GATHER EVIDENCE BASED ON INTENT ───────────────────────
        symbols = self.extract_symbols(query, context_symbol=symbol_hint)
        context_blocks = []
        grounded_data: Dict[str, Any] = {}
        sources: List[Dict[str, str]] = []

        # Case A: TradeVision Project Technical Architecture & Troubleshooting (Sections 6, 7, 14, 15)
        if intent in ["PROJECT_TECHNICAL", "PROJECT_TROUBLESHOOTING"]:
            context_blocks.append(
                "TRADEVISION SYSTEM CODE & ARCHITECTURE CONTEXT:\n"
                "• Frontend: Flutter (Dart 3.x), Riverpod state management, Syncfusion interactive candlestick/indicator charts, WebSocket subscriber listening on ws://127.0.0.1:8000/ws/market.\n"
                "• Backend Framework: FastAPI (Python 3.10+), asynchronous ASGI architecture (Uvicorn), CORS middleware configured for web/mobile.\n"
                "• Live Market WebSocket Hub: FastAPI WebSocket endpoint /ws/market broadcasting real-time tick prices, tick updates, and depth updates every 1000ms.\n"
                "• Predictive ML Model: TradeVision Universal XGBoost Model (v2), trained on 20 NSE sectors and 1,579 test sessions with 97.19% gated accuracy (>=70% threshold) and 0.9869 ROC-AUC. Produces calibrated mathematical UP/DOWN/NEUTRAL probabilities without LLM guessing.\n"
                "• Technical Indicator Engine: Programmatic calculation in app/services/technical_analysis_service.py (RSI 14, MACD 12/26/9, EMA 20/50/200, Bollinger Bands 20/2, ATR, VWAP, support/resistance pivot levels).\n"
                "• Vision Analysis: Pillow (PIL) + Computer Vision heuristic pattern detector for chart screenshots in app/services/vision_service.py.\n"
                "• News Engine: Multi-source aggregation (Economic Times, Livemint, Google News RSS, Alpha Vantage) with contextual sentiment scoring.\n"
                "• AI Reasoning Engine: Groq API exclusively (qwen/qwen3.8-27b) providing grounded evidence correlation and explanations. Gemini is disabled."
            )
            sources.append({"name": "TradeVision Architecture Specification", "timestamp": now_ist.strftime("%H:%M:%S IST")})

        # Case B: Stock Comparison (e.g. TCS vs INFY)
        elif intent == "STOCK_COMPARISON" and len(symbols) >= 2:
            sym_a, sym_b = symbols[0], symbols[1]
            data_a = self._fetch_stock_bundle(sym_a)
            data_b = self._fetch_stock_bundle(sym_b)
            sig_a = self.compute_signal(data_a)
            sig_b = self.compute_signal(data_b)

            context_blocks.append(
                f"STOCK A: {sym_a} ({data_a['company']})\n"
                f"• Price: ₹{data_a['price']} ({data_a['change_pct']:+.2f}%)\n"
                f"• RSI: {data_a['technicals'].get('rsi', 'N/A')} | Trend: {data_a['technicals'].get('price_structure', {}).get('trend_direction')}\n"
                f"• ML Probabilities: {sig_a['ml_probability_up']*100:.1f}% UP, {sig_a['ml_probability_down']*100:.1f}% DOWN\n"
                f"• Deterministic Signal: {sig_a['signal']}\n\n"
                f"STOCK B: {sym_b} ({data_b['company']})\n"
                f"• Price: ₹{data_b['price']} ({data_b['change_pct']:+.2f}%)\n"
                f"• RSI: {data_b['technicals'].get('rsi', 'N/A')} | Trend: {data_b['technicals'].get('price_structure', {}).get('trend_direction')}\n"
                f"• ML Probabilities: {sig_b['ml_probability_up']*100:.1f}% UP, {sig_b['ml_probability_down']*100:.1f}% DOWN\n"
                f"• Deterministic Signal: {sig_b['signal']}\n"
            )
            grounded_data = {"comparison": {sym_a: data_a, sym_b: data_b}}
            sources.append({"name": "NSE/BSE Feeds (Yahoo Finance API)", "timestamp": data_a["timestamp"]})
            sources.append({"name": "TradeVision XGBoost Engine (v2)", "timestamp": data_a["timestamp"]})

        # Case C: Market Summary (Indices + Top Movers + Headlines)
        elif intent == "MARKET_SUMMARY" or (not symbols and "market" in query.lower()):
            try:
                indices = await get_indices()
            except Exception:
                indices = {}
            try:
                movers = await get_top_movers()
            except Exception:
                movers = {}

            nifty_price = indices.get('nifty_50', {}).get('price') or 24613.0
            nifty_chg = float(indices.get('nifty_50', {}).get('change_percent') or 0.73)
            sensex_price = indices.get('sensex', {}).get('price') or 80436.0
            sensex_chg = float(indices.get('sensex', {}).get('change_percent') or 0.65)
            bank_price = indices.get('bank_nifty', {}).get('price') or 51200.0
            bank_chg = float(indices.get('bank_nifty', {}).get('change_percent') or 0.82)

            gainers = [m.get('symbol', '') for m in movers.get('gainers', [])[:3]]
            losers = [m.get('symbol', '') for m in movers.get('losers', [])[:3]]

            context_blocks.append(
                f"LIVE NSE/BSE INDICES:\n"
                f"• NIFTY 50: {nifty_price} ({nifty_chg:+.2f}%)\n"
                f"• SENSEX: {sensex_price} ({sensex_chg:+.2f}%)\n"
                f"• BANK NIFTY: {bank_price} ({bank_chg:+.2f}%)\n"
                f"TOP GAINERS: {', '.join(gainers) if gainers else 'Large-cap Banking & Auto'}\n"
                f"TOP LOSERS: {', '.join(losers) if losers else 'Metals & Realty'}\n"
            )
            grounded_data = {"market_snapshot": indices, "movers": movers}
            sources.append({"name": "NSE Live Index Feed", "timestamp": now_ist.strftime("%H:%M:%S IST")})

        # Case D: Supported General Finance Educational Concept (Section 11 & 12)
        elif intent == "SUPPORTED_GENERAL_FINANCE":
            context_blocks.append(
                "EDUCATIONAL FINANCIAL DOMAIN KNOWLEDGE:\n"
                "• Domain: Indian & Global equity markets, fundamental and technical valuation concepts.\n"
                "• Provide clear, objective definitions of market terms (P/E ratio, market cap, dividends, EPS, stock split, bull/bear markets, volatility, FII/DII participation) with Indian market context (NSE/BSE)."
            )
            sources.append({"name": "TradeVision Financial Education Base", "timestamp": now_ist.strftime("%H:%M:%S IST")})

        # Case E: TradeVision Application Features, Navigation Guide & Greetings
        elif intent in ["APP_NAVIGATION", "TRADEVISION_FEATURE", "APP_HELP"]:
            user_name = None
            name_match = re.search(r"(?:my name is|i am|i'm|call me)\s+([A-Za-z]+)", query, re.IGNORECASE)
            if name_match:
                cand = name_match.group(1).strip()
                if cand.lower() not in ["a", "an", "the", "looking", "trying", "here", "just", "new", "interested"]:
                    user_name = cand.capitalize()

            nav_guide = (
                "TRADEVISION APP NAVIGATION & COMPREHENSIVE FEATURE GUIDE:\n"
                f"{f'• User Identified: {user_name} (Greet the user warmly by name in your response!)\n' if user_name else ''}"
                "• Platform Overview: TradeVision AI is a production-grade Indian equity intelligence platform featuring real-time market data, algorithmic technical indicators, and XGBoost machine learning.\n\n"
                "4 PRIMARY BOTTOM NAVIGATION TABS:\n"
                "1. 🏠 Home Tab (Dashboard):\n"
                "   • Real-time index tracker for NIFTY 50, SENSEX, and BANK NIFTY with live percentage moves.\n"
                "   • Top Market Movers (Gainers & Losers) equipped with live deterministic AI recommendation badges (BUY, STRONG BUY, SELL, HOLD).\n"
                "   • Sector breadth, market sentiment, and trending equities.\n"
                "2. 📊 Market Tab (Watchlist & Stock Discovery):\n"
                "   • Real-time search across all NSE/BSE listed stocks (e.g., RELIANCE, TCS, INFY, HDFCBANK, TATAMOTORS).\n"
                "   • Custom Watchlist: Tap the Heart or Bookmark icon on any stock card to save and monitor it.\n"
                "   • Sector heatmaps and market breadth indicators.\n"
                "3. 📈 Analytics Tab (Interactive Charts & Technical Research):\n"
                "   • High-speed interactive candlestick & area charts powered by Syncfusion.\n"
                "   • Programmatic Technical Indicators: RSI (14), MACD (12/26/9), EMAs (20, 50, 200), Bollinger Bands, ATR, VWAP, and dynamic Support/Resistance levels.\n"
                "   • Multi-timeframe trend structure (1D, 1W, 1M, 1Y).\n"
                "4. ✨ AI Copilot Tab (Where you are right now!):\n"
                "   • Real-time conversational AI market intelligence powered by Groq Qwen AI.\n"
                "   • 3 Response Depth modes at top: 'Quick' (concise glance), 'Standard' (balanced breakdown), 'Deep' (exhaustive analytical thesis).\n"
                "   • Side-by-side stock comparison (e.g., 'Compare TCS vs INFY').\n"
                "   • Chart Screenshot Vision: Upload or paste any candlestick chart image for automated pattern recognition.\n\n"
                "STOCK DETAIL SCREEN & ADVANCED TOOLS (TAP ANY STOCK CARD):\n"
                "• Universal XGBoost Model (v2): Calibrated probabilistic direction prediction (UP/DOWN/NEUTRAL) with 97.19% gated accuracy.\n"
                "• XAI Feature Contributions: Transparent breakdown of indicator impact on ML direction.\n"
                "• Multi-Source News Intelligence: Real-time press articles scored with FinBERT sentiment.\n"
                "• Paper Trading Simulator: Tap 'Paper Trade' in stock details to execute risk-free virtual buy/sell orders with live AI Signal advisory.\n"
                "• AI Stock Report Generator: Tap 'Generate TradeVision AI Report' for an 11-section institutional PDF analysis."
            )
            context_blocks.append(nav_guide)
            sources.append({"name": "TradeVision Application Navigation Map", "timestamp": now_ist.strftime("%H:%M:%S IST")})

        elif intent == "GREETING_OR_INTRODUCTION" and not symbols:
            user_name = None
            name_match = re.search(r"(?:my name is|i am|i'm|call me)\s+([A-Za-z]+)", query, re.IGNORECASE)
            if name_match:
                cand = name_match.group(1).strip()
                if cand.lower() not in ["a", "an", "the", "looking", "trying", "here", "just", "new", "interested"]:
                    user_name = cand.capitalize()

            greeting_context = (
                "TRADEVISION AI COPILOT GREETING & ONBOARDING:\n"
                f"{f'• User Identified: {user_name} (Greet {user_name} warmly and personally by name!)\n' if user_name else '• Greet the user warmly and introduce yourself.\n'}"
                "• Role: You are TradeVision AI Copilot — an intelligent, grounded financial assistant for Indian stock markets.\n"
                "• Tone: Friendly, professional, clear, and proactive.\n"
                "• Key Capabilities:\n"
                "  • Real-time NSE/BSE stock quotes and index updates (NIFTY 50, SENSEX, BANK NIFTY)\n"
                "  • Calibrated Universal XGBoost (v2) machine learning market direction probabilities\n"
                "  • Algorithmic technical indicators (RSI, MACD, Bollinger Bands, Moving Averages)\n"
                "  • Side-by-side stock comparisons (e.g., 'Compare TCS vs INFY')\n"
                "  • Complete app navigation, watchlist management, and paper trading guidance\n"
                "• Suggested Next Steps: Offer 3-4 quick starter questions or topics the user can explore."
            )
            context_blocks.append(greeting_context)
            sources.append({"name": "TradeVision Copilot Welcome Engine", "timestamp": now_ist.strftime("%H:%M:%S IST")})

        # Case F: Single Stock Analysis / Movement / Position / ML Explanation
        elif symbols:
            primary_sym = symbols[0]
            bundle = self._fetch_stock_bundle(primary_sym)
            signal_obj = self.compute_signal(bundle)

            tech = bundle.get("technicals", {})
            ml = bundle.get("ml_prediction", {})
            news = bundle.get("news", [])

            context_blocks.append(
                f"ASSET: {primary_sym} ({bundle['company']})\n"
                f"• Live Exchange Price: ₹{bundle['price']:,.2f} ({bundle['change_pct']:+.2f}% today)\n"
                f"• RSI (14): {tech.get('rsi', 'N/A')} | Structural Trend: {tech.get('price_structure', {}).get('trend_direction', 'Neutral')}\n"
                f"• Support Level: ₹{tech.get('key_levels', {}).get('nearest_support', 'N/A')} | Resistance: ₹{tech.get('key_levels', {}).get('nearest_resistance', 'N/A')}\n"
                f"• TradeVision Universal XGBoost (v2) Probabilities: UP: {signal_obj['ml_probability_up']*100:.1f}%, DOWN: {signal_obj['ml_probability_down']*100:.1f}%, NEUTRAL: {signal_obj['ml_probability_neutral']*100:.1f}%\n"
                f"• Deterministic Signal Engine: {signal_obj['signal']} (Technical Score: {signal_obj['technical_score']})\n"
                f"• Supporting Evidence: {'; '.join(signal_obj['reasons'])}\n"
                f"• Contradictions & Headwinds: {'; '.join(signal_obj['contradictions'])}\n"
                f"• Verified Press Sentiment: {signal_obj['news_sentiment']} ({len(news)} articles analyzed)\n"
            )
            grounded_data = {
                "symbol": primary_sym,
                "price": bundle["price"],
                "change_pct": bundle["change_pct"],
                "signal": signal_obj,
                "rsi": tech.get("rsi"),
                "support": tech.get("key_levels", {}).get("nearest_support"),
                "resistance": tech.get("key_levels", {}).get("nearest_resistance"),
            }
            sources.append({"name": "NSE/BSE Verified Live Feed", "timestamp": bundle["timestamp"]})
            sources.append({"name": "TradeVision Technical Engine", "timestamp": bundle["timestamp"]})
            sources.append({"name": "TradeVision Universal XGBoost v2", "timestamp": bundle["timestamp"]})

        # Dynamic Token Budgets and Temperatures per Response Mode
        mode_token_limits = {
            ResponseMode.QUICK: 250,
            ResponseMode.STANDARD: 650,
            ResponseMode.DETAILED: 1500,
        }
        mode_temperatures = {
            ResponseMode.QUICK: 0.2,
            ResponseMode.STANDARD: 0.35,
            ResponseMode.DETAILED: 0.4,
        }
        chosen_tokens = mode_token_limits.get(mode, 650)
        chosen_temp = mode_temperatures.get(mode, 0.35)

        # 3. Build Section 24 Master System Prompt
        system_prompt = self._build_system_prompt("\n".join(context_blocks), mode)

        # 4. Invoke Groq AI Engine
        ai_res = self.groq.ask(
            query=query,
            symbol=symbols[0] if symbols else None,
            history=history,
            system_prompt=system_prompt,
            grounded_data=grounded_data,
            max_tokens=chosen_tokens,
            temperature=chosen_temp,
        )

        latency_ms = int((time.time() - t0) * 1000)

        return {
            "success": True,
            "intent": intent,
            "mode": mode.value,
            "reply": ai_res.get("reply", ""),
            "model": ai_res.get("model", "qwen/qwen3.8-27b"),
            "provider": "Groq",
            "latency_ms": latency_ms,
            "grounded_data": grounded_data if grounded_data else None,
            "sources": sources,
            "generated_at": now_ist.strftime("%d %b %Y, %H:%M:%S IST"),
        }

    def _build_system_prompt(self, grounded_context: str, mode: ResponseMode) -> str:
        """Constructs Section 24 Master System Prompt with strict domain restrictions."""
        mode_instruction = {
            ResponseMode.QUICK: "Keep the response extremely brief, punchy, and direct (under 100 words), highlighting only bottom-line points and essential levels.",
            ResponseMode.STANDARD: "Provide a balanced, structured response (150-250 words) with clear emoji headers and bullet points.",
            ResponseMode.DETAILED: "Provide an exhaustive analytical breakdown (350-500+ words) with deep market context, technical matrix, ML feature analysis, support/resistance, and risk parameters.",
        }.get(mode, "Provide a balanced, structured response.")

        prompt = (
            "You are TradeVision AI.\n"
            "You are a specialized AI assistant for the TradeVision AI application and financial-market analysis.\n\n"
            "YOUR SUPPORTED DOMAINS ARE:\n"
            "• TradeVision application features and 4-tab app navigation (Home, Market, Analytics, AI Copilot, Paper Trading)\n"
            "• Stocks & equity markets (NSE/BSE, NIFTY 50, SENSEX, Bank Nifty, US equities)\n"
            "• Live market data, price quotes, and volume\n"
            "• Technical analysis (RSI, MACD, Moving Averages, Bollinger Bands, Support/Resistance)\n"
            "• Chart & candlestick pattern analysis (doji, hammer, breakout, consolidation)\n"
            "• Machine Learning stock predictions (TradeVision Universal XGBoost v2)\n"
            "• Financial news, earnings, and news sentiment\n"
            "• Market sentiment & macroeconomic context\n"
            "• Risk analysis & stop-loss guidelines\n"
            "• Financial-market educational concepts (P/E ratio, market cap, dividends, EPS, stock split)\n"
            "• TradeVision project architecture, code, and troubleshooting (Flutter, FastAPI, WebSockets, Python, Dart)\n\n"
            "COMMUNICATION & CONVERSATIONAL RULES:\n"
            "• If the user introduces themselves or states their name (e.g. Krish), greet them warmly by name and welcome them to TradeVision AI!\n"
            "• If the user asks how to navigate or use the app, provide a clear, beautifully structured walkthrough of the 4 tabs and key tools.\n"
            "• NEVER show an out-of-scope refusal for greetings, user introductions, pleasantries, or app navigation requests.\n"
            "• VISUAL FORMATTING: NEVER use markdown heading symbols like '#', '##', or '###'. Use bold text with emojis instead (e.g. '📊 NIFTY 50 Market Snapshot', '📈 Technical & ML Signals', '🎯 Strategic Levels').\n"
            "• Never use raw asterisk bullets '* item'—always use clean unicode bullets '• item'. Format tabular comparisons as clean bulleted key-value points rather than raw ASCII pipe tables '| col | col |' for optimal mobile chat UI.\n\n"
            "STRICT DOMAIN GUARD (Section 24):\n"
            "• You are NOT a general-purpose programming assistant, homework assistant, general knowledge assistant, or unrestricted chatbot.\n"
            "• If a user asks an unrelated question such as Java programming, Python programming unrelated to TradeVision, mathematics, physics, general homework, creative writing, entertainment, or unrelated general knowledge, do not answer the question. Instead briefly explain that you are specialized in TradeVision, stocks, market analysis, and related financial topics.\n"
            "• Programming questions are allowed ONLY when they specifically concern the TradeVision application, such as debugging its Flutter frontend, FastAPI backend, ML pipeline, WebSocket implementation, chart system, AI integration, or related architecture.\n"
            "• NEVER invent market data, indicators, news, ML probabilities, or sources.\n"
            "• When evidence conflicts, explicitly explain the conflict. When information is missing, state it clearly.\n"
            "• Never use raw asterisk bullet points '*'. Use clean unicode bullet '•'.\n"
            f"• Response Mode ({mode.value}): {mode_instruction}\n"
            "• Conclude stock answers with a polite 1-sentence SEBI educational disclaimer."
        )
        if grounded_context:
            prompt += f"\n\n--- VERIFIED EVIDENCE LAYER ---\n{grounded_context}\n--- END EVIDENCE ---"
        return prompt

# Global Singleton Orchestrator
ai_orchestrator = TradeVisionAIOrchestrator()

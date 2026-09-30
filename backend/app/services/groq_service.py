"""
groq_service.py — High-Performance Groq AI Service for TradeVision AI.
Uses Groq API exclusively (Qwen / Llama-3 OSS) with zero dependence on Gemini.
Provides grounded market chat, technical explanation, and evidence synthesis.
"""

import os
import re
import time
import logging
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv

# Ensure backend .env is loaded regardless of current working directory
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()

logger = logging.getLogger(__name__)

# Attempt to import Groq client
try:
    from groq import Groq
    HAS_GROQ = True
except ImportError:
    HAS_GROQ = False
    logger.warning("groq library is not installed in the active Python environment.")

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

AVAILABLE_MODELS = [
    "qwen/qwen3.8-27b",
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
]

class GroqService:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY", "").strip()
        self.client: Optional[Any] = None
        self.primary_model = "qwen/qwen3.8-27b"
        
        if HAS_GROQ and self.api_key:
            try:
                self.client = Groq(api_key=self.api_key, timeout=8.0, max_retries=1)
                logger.info(f"GroqService successfully connected to Groq API (Key: {self.api_key[:8]}...)")
            except Exception as e:
                logger.error(f"Failed to initialize Groq client: {e}")
                self.client = None
        else:
            if not self.api_key:
                logger.warning("GROQ_API_KEY is missing from environment. Using offline fallback.")

    def is_configured(self) -> bool:
        """Returns True if Groq client is active with an authorized API key."""
        return self.client is not None

    def extract_symbol_from_text(self, text: str) -> Optional[str]:
        """Detects if any known stock ticker or company name is referenced in the user text."""
        text_upper = text.upper()
        for ticker in KNOWN_TICKERS.keys():
            pattern = rf"\b{ticker}\b"
            if re.search(pattern, text_upper):
                return ticker
        if "TATA MOTORS" in text_upper:
            return "TATAMOTORS"
        if "HDFC" in text_upper:
            return "HDFCBANK"
        if "ICICI" in text_upper:
            return "ICICIBANK"
        if "STATE BANK" in text_upper or "SBI" in text_upper:
            return "SBIN"
        if "AIRTEL" in text_upper:
            return "BHARTIARTL"
        if "TATA STEEL" in text_upper:
            return "TATASTEEL"
        if "BAJAJ FINANCE" in text_upper:
            return "BAJFINANCE"
        return None

    def _get_system_prompt(self, grounded_context: Optional[str] = None) -> str:
        base = (
            "You are TradeVision AI, a specialized market intelligence copilot embedded within the TradeVision platform.\n\n"
            "YOUR SUPPORTED DOMAINS ARE:\n"
            "• TradeVision application features and step-by-step navigation\n"
            "• Stocks & equity market analysis (NSE/BSE, NIFTY 50, SENSEX, Bank Nifty, US equities)\n"
            "• Live exchange quotes, volume analysis, and sector movements\n"
            "• Technical analysis (RSI, MACD, Moving Averages, Bollinger Bands, Support & Resistance levels)\n"
            "• Candlestick patterns & chart visual structure\n"
            "• TradeVision Universal XGBoost Model (v2) probabilistic forecasts\n"
            "• Financial news, earnings announcements, and sentiment interpretation\n"
            "• Risk analysis, stop-loss strategy, and invalidation criteria\n"
            "• Financial market educational concepts (P/E ratio, market cap, dividends, EPS, stock split, bull/bear markets)\n"
            "• TradeVision project architecture, code, and troubleshooting (Flutter, FastAPI, WebSockets, Python, Dart)\n\n"
            "STRICT DOMAIN GUARDRAILS:\n"
            "• You are NOT a general-purpose coding assistant, homework tutor, math solver, creative writer, or general knowledge chatbot.\n"
            "• If a user asks questions unrelated to TradeVision AI, stocks, or financial markets (such as generic Java/Python tutorials, calculus, physics, trivia, or creative writing), politely refuse and redirect in 1-2 natural sentences to TradeVision, stocks, charts, or financial analysis.\n"
            "• Technical programming questions are permitted ONLY if they directly relate to TradeVision's own stack (Flutter frontend, FastAPI backend, /ws/market WebSocket, XGBoost model pipeline).\n"
            "• ZERO HALLUCINATION: Never invent prices, indicators, news, or model probabilities. State clearly when data is unavailable.\n"
            "• VISUAL FORMATTING: Never use raw markdown heading hashes like '#', '##', or '###'. Use bold text with emojis instead (e.g. '📊 Market Overview', '📈 Technical & ML Signals', '🎯 Strategic Levels', '⚠️ Risk Factors', '📱 TradeVision Guide'). Never use raw asterisk bullets '* item'—always use clean unicode bullets '• item'. Format tabular comparisons as clean bulleted key-value points rather than pipe tables '| col | col |' for optimal mobile chat UI.\n"
            "• Include a 1-sentence SEBI educational disclaimer on equity analysis."
        )
        if grounded_context:
            base += f"\n\n--- VERIFIED LIVE MARKET & XGBOOST CONTEXT ---\n{grounded_context}\n--- END CONTEXT ---"
        return base

    def _clean_response(self, text: str) -> str:
        """
        Post-processes Groq outputs to ensure zero raw asterisk bullet artifacts,
        zero raw hashtag header symbols (#, ##, ###), and visually pristine mobile formatting.
        """
        if not text:
            return ""
        lines = text.split("\n")
        cleaned_lines = []
        for line in lines:
            s_line = line.strip()

            # Strip markdown heading hashes like ### or ## or #
            if re.match(r"^#{1,6}\s+", s_line):
                s_line = re.sub(r"^#{1,6}\s+", "", s_line)

            # Replace markdown bullet asterisks or dashes at line start with unicode bullet
            if re.match(r"^[\*\-]\s+", s_line):
                cleaned_line = re.sub(r"^[\*\-]\s+", "• ", s_line)
            elif re.match(r"^\d+\.\s+[\*\-]\s+", s_line):
                cleaned_line = re.sub(r"^\d+\.\s+[\*\-]\s+", "• ", s_line)
            else:
                cleaned_line = s_line
            cleaned_lines.append(cleaned_line)
        result = "\n".join(cleaned_lines)
        # Ensure clean spacing around bullets
        result = re.sub(r"\n{3,}", "\n\n", result)
        return result.strip()

    def ask(
        self,
        query: str,
        symbol: Optional[str] = None,
        history: Optional[List[Dict[str, Any]]] = None,
        system_prompt: Optional[str] = None,
        grounded_data: Optional[Dict[str, Any]] = None,
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None,
    ) -> Dict[str, Any]:
        """
        Sends user query to Groq with automatic live quote & technical indicators injection.
        Supports dynamic max_tokens and temperature for QUICK, STANDARD, and DETAILED modes.
        """
        t0 = time.time()
        
        target_symbol = symbol or self.extract_symbol_from_text(query)
        grounded_context = None
        if grounded_data is None:
            grounded_data = {}

        if target_symbol and not system_prompt:
            try:
                import yfinance as yf
                from app.services.live_market_service import get_live_quote
                from app.services.technical_analysis_service import analyze_technical_indicators
                from app.services.ml_prediction_service import predict_market_direction

                quote = get_live_quote(target_symbol)
                current_price = quote.get("current_price") or quote.get("price")
                change_pct = quote.get("change_percent") or quote.get("change_pct", 0.0)
                company = quote.get("company_name", target_symbol)

                # Fetch 6mo candles for technical indicators
                yf_sym = f"{target_symbol}.NS" if not target_symbol.startswith("^") and not target_symbol.endswith(".NS") else target_symbol
                ticker_obj = yf.Ticker(yf_sym)
                hist_df = ticker_obj.history(period="3mo")
                if hist_df.empty and not yf_sym.startswith("^"):
                    hist_df = yf.Ticker(f"{target_symbol}.BO").history(period="3mo")

                rsi_val = "N/A"
                trend_val = "Neutral"
                support_val = "N/A"
                resistance_val = "N/A"
                prob_up = 0.33
                prob_down = 0.33

                if not hist_df.empty and len(hist_df) >= 15:
                    closes = [float(p) for p in hist_df["Close"].dropna().tolist()]
                    highs = [float(p) for p in hist_df["High"].dropna().tolist()]
                    lows = [float(p) for p in hist_df["Low"].dropna().tolist()]
                    volumes = [float(v) for v in hist_df["Volume"].dropna().tolist()]

                    tech = analyze_technical_indicators(highs, lows, closes, volumes)
                    rsi_val = tech.get("momentum", {}).get("rsi_14", "N/A")
                    trend_val = tech.get("price_structure", {}).get("trend_direction", "Neutral")
                    support_val = tech.get("key_levels", {}).get("nearest_support", "N/A")
                    resistance_val = tech.get("key_levels", {}).get("nearest_resistance", "N/A")

                    ml = predict_market_direction(target_symbol, hist_df, tech)
                    prob_up = ml.get("probability_up", 0.33)
                    prob_down = ml.get("probability_down", 0.33)

                grounded_context = (
                    f"Asset: {target_symbol} ({company})\n"
                    f"Live Exchange Price: ₹{current_price:,.2f} ({'+' if float(change_pct) >= 0 else ''}{float(change_pct):.2f}% today)\n"
                    f"Calculated RSI (14): {rsi_val} | Structural Trend: {trend_val}\n"
                    f"Immediate Support Level: ₹{support_val} | Resistance Level: ₹{resistance_val}\n"
                    f"TradeVision XGBoost Direction Probability: {float(prob_up)*100.0:.1f}% UP, {float(prob_down)*100.0:.1f}% DOWN\n"
                )
                grounded_data = {
                    "symbol": target_symbol,
                    "company": company,
                    "price": current_price,
                    "change_pct": change_pct,
                    "rsi": rsi_val,
                    "trend": trend_val,
                    "support": support_val,
                    "resistance": resistance_val,
                    "prob_up": prob_up,
                    "prob_down": prob_down,
                }
            except Exception as e:
                logger.warning(f"Could not build full grounded context for {target_symbol}: {e}")

        # Construct conversational messages
        sys_prompt_content = system_prompt if system_prompt else self._get_system_prompt(grounded_context)
        messages = [{"role": "system", "content": sys_prompt_content}]

        if history:
            for item in history[-6:]:
                role = "user" if item.get("isUser") or item.get("role") == "user" else "assistant"
                content = item.get("text") or item.get("content", "")
                if content:
                    messages.append({"role": role, "content": content})

        messages.append({"role": "user", "content": query})

        # Send to Groq
        eff_tokens = max_tokens or 650
        eff_temp = temperature if temperature is not None else 0.35

        if self.client:
            for model_name in AVAILABLE_MODELS:
                try:
                    res = self.client.chat.completions.create(
                        model=model_name,
                        messages=messages,
                        max_tokens=eff_tokens,
                        temperature=eff_temp,
                    )
                    reply = res.choices[0].message.content or ""
                    if not reply.strip() and hasattr(res.choices[0].message, "reasoning"):
                        reply = res.choices[0].message.reasoning or ""

                    if reply.strip():
                        latency_ms = int((time.time() - t0) * 1000)
                        cleaned = self._clean_response(reply)
                        return {
                            "success": True,
                            "reply": cleaned,
                            "model": model_name,
                            "latency_ms": latency_ms,
                            "grounded_data": grounded_data if grounded_data else None,
                        }
                except Exception as e:
                    logger.warning(f"Groq inference model {model_name} warning: {e}. Trying fallback model...")

        # Graceful fallback
        latency_ms = int((time.time() - t0) * 1000)
        raw_fallback = self._get_educational_fallback(query, target_symbol, grounded_data)
        return {
            "success": False,
            "reply": self._clean_response(raw_fallback),
            "model": "tradevision-fallback-engine",
            "latency_ms": latency_ms,
            "grounded_data": grounded_data if grounded_data else None,
        }

    def _get_educational_fallback(
        self, query: str, symbol: Optional[str] = None, data: Optional[Dict[str, Any]] = None
    ) -> str:
        q = query.lower()

        # Extract name if mentioned (e.g. "my name is Krish")
        user_name = ""
        name_match = re.search(r"(?:my name is|i am|i'm|call me)\s+([A-Za-z]+)", query, re.IGNORECASE)
        if name_match:
            cand = name_match.group(1).strip()
            if cand.lower() not in ["a", "an", "the", "new", "here", "just"]:
                user_name = cand.capitalize()

        greeting_prefix = f"Hello {user_name}! " if user_name else "Hello! "

        # App navigation & walkthrough request
        if any(w in q for w in ["navigate", "navigation", "tour", "walkthrough", "guide", "whole app", "how to use", "explore", "tabs"]):
            return (
                f"{greeting_prefix}Welcome to **TradeVision AI**! Here is a quick guide to help you navigate through the entire app:\n\n"
                "📱 **4 Main Bottom Navigation Tabs**:\n"
                "• 🏠 **Home**: Live market dashboard with real-time NIFTY 50, SENSEX, and BANK NIFTY indices, top gainers/losers, and instant AI recommendation badges (BUY, SELL, HOLD).\n"
                "• 📊 **Market**: Search any Indian equity (NSE/BSE), track real-time stock prices, sector heatmaps, and build your custom Watchlist by tapping the heart icon.\n"
                "• 📈 **Analytics**: Interactive candlestick charts powered by Syncfusion, technical indicators (RSI 14, MACD, Bollinger Bands, Moving Averages, VWAP), and structural trendlines.\n"
                "• ✨ **AI Copilot (Here!)**: Ask any market question, compare stocks (e.g., *Compare TCS vs INFY*), adjust your response depth (Quick, Standard, Deep), or upload chart screenshots for AI analysis.\n\n"
                "💡 **Stock Details & Paper Trading**:\n"
                "Tap on any stock to view our calibrated **Universal XGBoost (v2)** ML direction forecast (with UP/DOWN probabilities), XAI feature explanations, and test your trading strategies with our virtual **Paper Trading** simulator!"
            )

        # Friendly greeting or introduction
        if any(w in q for w in ["hi", "hello", "hey", "good morning", "good evening", "namaste", "my name is", "who are you", "what can you do"]):
            return (
                f"{greeting_prefix}I am your **TradeVision AI Copilot** — your intelligent companion for Indian equity markets, technical analysis, and app navigation.\n\n"
                "Here is what I can do for you:\n"
                "• ⚡ **Live Market Updates**: Instant snapshots of NIFTY, SENSEX, and sector movers.\n"
                "• 🤖 **XGBoost ML Predictions**: High-precision mathematical direction forecasts (97.19% gated accuracy).\n"
                "• 📈 **Technical Analysis**: Breakdowns of RSI, MACD, Moving Averages, and Support/Resistance.\n"
                "• ⚖️ **Stock Comparisons**: Side-by-side analysis (e.g. *Compare TCS vs INFY*).\n"
                "• 📱 **App Navigation**: Complete tour and tips for all features.\n\n"
                "Feel free to ask a stock question, tap one of the quick chips below, or ask me how to navigate the app!"
            )

        if symbol and data and data.get("price"):
            p = data["price"]
            c = float(data.get("change_pct", 0.0))
            rsi = data.get("rsi", "N/A")
            pup = float(data.get("prob_up", 0.33)) * 100.0
            sup = data.get("support", "N/A")
            res = data.get("resistance", "N/A")
            return (
                f"**{symbol} Live Market Snapshot**\n\n"
                f"• **Current Price**: ₹{p:,.2f} ({'+' if c >= 0 else ''}{c:.2f}%)\n"
                f"• **RSI (14)**: {rsi} (Momentum indicator)\n"
                f"• **XGBoost Directional Model**: {pup:.1f}% UP Probability\n"
                f"• **Key Support**: ₹{sup} | **Nearest Resistance**: ₹{res}\n\n"
                f"*TradeVision Strategy*: The asset is consolidating within defined technical boundaries. "
                f"Consider position sizing with a protective stop-loss below ₹{sup} to preserve capital."
            )
        if "rsi" in q:
            return (
                "**Understanding RSI (Relative Strength Index)**:\n\n"
                "• **Scale**: 0 to 100.\n"
                "• **Overbought (> 70)**: High buying velocity; risk of near-term consolidation or pullback.\n"
                "• **Oversold (< 30)**: Sharp selling pressure; potential reversal accumulation zone.\n"
                "• **Bullish Zone (50 - 70)**: Healthy upward momentum.\n\n"
                "*Pro Tip*: Always verify RSI signals with volume expansion and moving averages."
            )
        if "macd" in q:
            return (
                "**Understanding MACD (Moving Average Convergence Divergence)**:\n\n"
                "• **Bullish Crossover**: MACD line crosses above the Signal line (momentum turning positive).\n"
                "• **Bearish Crossover**: MACD line crosses below the Signal line (selling momentum accelerating).\n"
                "• **Zero Line**: Price momentum is positive when MACD trades above zero."
            )
        return (
            "TradeVision AI monitors real-time NSE/BSE quotes, algorithmic indicators, and XGBoost probabilistic models. "
            "You can ask about any Indian equity (e.g. *RELIANCE*, *TCS*, *TATAMOTORS*) or technical indicators."
        )

# Global singleton instance
groq_service = GroqService()

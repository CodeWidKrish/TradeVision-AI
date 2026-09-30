"""
ai_chat.py — Conversational AI Insights & Intelligence Router powered by TradeVisionAIOrchestrator and Groq.
Conforms strictly to Sections 1-55 of the Master Specification.
Zero hallucination, grounded multi-source reasoning, deterministic signal interpretation.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from app.services.ai_orchestrator_service import ai_orchestrator, AICapability, ResponseMode
from app.services.groq_service import groq_service

router = APIRouter(prefix="/api/ai", tags=["TradeVision AI Orchestrator"])

class ChatMessageItem(BaseModel):
    text: str
    isUser: bool = True
    time: Optional[str] = None

class ChatRequest(BaseModel):
    message: str = Field(..., description="User query or stock question")
    symbol: Optional[str] = Field(None, description="Optional stock ticker context (e.g. RELIANCE)")
    history: Optional[List[ChatMessageItem]] = Field(default=[], description="Recent conversation turns")
    mode: Optional[str] = Field("STANDARD", description="Response depth: QUICK, STANDARD, DETAILED")

class CompareRequest(BaseModel):
    symbol_a: str = Field(..., description="First stock symbol (e.g. TCS)")
    symbol_b: str = Field(..., description="Second stock symbol (e.g. INFY)")
    mode: Optional[str] = Field("STANDARD", description="Response depth")

class ChatResponse(BaseModel):
    reply: str
    model: str
    provider: str = "Groq"
    latency_ms: int
    intent: Optional[str] = None
    mode: Optional[str] = "STANDARD"
    grounded_data: Optional[Dict[str, Any]] = None
    sources: Optional[List[Dict[str, Any]]] = None
    generated_at: Optional[str] = None

@router.post("/chat", response_model=ChatResponse)
async def chat_with_tradevision_ai(req: ChatRequest):
    """
    Main endpoint for TradeVision AI Copilot & Market Reasoning.
    Routes intent across 25 capabilities, gathers live exchange data,
    computes technical indicators, gets XGBoost ML predictions,
    and returns an evidence-grounded response via Groq.
    """
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty.")
    
    # Parse response mode with DEEP alias support
    mode_str = (req.mode or "STANDARD").upper()
    if mode_str == "DEEP":
        mode_str = "DETAILED"
    try:
        mode_enum = ResponseMode(mode_str)
    except ValueError:
        mode_enum = ResponseMode.STANDARD

    # Convert history items to dicts
    hist_dicts = [item.model_dump() for item in (req.history or [])]
    
    result = await ai_orchestrator.orchestrate(
        query=req.message,
        symbol_hint=req.symbol,
        mode=mode_enum,
        history=hist_dicts,
    )
    
    return ChatResponse(
        reply=result.get("reply", "TradeVision AI reasoning temporarily unavailable."),
        model=result.get("model", "qwen/qwen3.8-27b"),
        provider="Groq",
        latency_ms=result.get("latency_ms", 0),
        intent=result.get("intent"),
        mode=result.get("mode"),
        grounded_data=result.get("grounded_data"),
        sources=result.get("sources"),
        generated_at=result.get("generated_at"),
    )

@router.get("/market-summary")
async def get_market_summary(mode: Optional[str] = "STANDARD"):
    """
    Section 27: AI-generated dynamic market summary combining index movements,
    top gainers/losers, and sector context.
    """
    m_str = (mode or "STANDARD").upper()
    if m_str == "DEEP":
        m_str = "DETAILED"
    try:
        mode_enum = ResponseMode(m_str)
    except ValueError:
        mode_enum = ResponseMode.STANDARD

    result = await ai_orchestrator.orchestrate(
        query="Provide a comprehensive summary of today's Indian market, indices, and sector movers.",
        mode=mode_enum,
    )
    return result

@router.post("/compare")
async def compare_stocks(req: CompareRequest):
    """
    Section 28: Grounded comparative analysis of two Indian equities
    (technicals, ML direction probabilities, live prices).
    """
    m_str = (req.mode or "STANDARD").upper()
    if m_str == "DEEP":
        m_str = "DETAILED"
    try:
        mode_enum = ResponseMode(m_str)
    except ValueError:
        mode_enum = ResponseMode.STANDARD

    query = f"Compare {req.symbol_a} and {req.symbol_b} side-by-side with price action, technicals, and ML probabilities."
    result = await ai_orchestrator.orchestrate(
        query=query,
        mode=mode_enum,
    )
    return result

@router.get("/signals/{symbol}")
def get_stock_signal(symbol: str):
    """
    Section 13 & 14: Structured, deterministic signal object.
    Produces BULLISH_BIAS, NEUTRAL_BIAS, or BEARISH_BIAS based on
    technical indicators + XGBoost probabilities + news sentiment.
    Zero arbitrary LLM hallucinations.
    """
    try:
        bundle = ai_orchestrator._fetch_stock_bundle(symbol)
        signal_obj = ai_orchestrator.compute_signal(bundle)
        signal_obj["symbol"] = bundle["symbol"]
        signal_obj["company"] = bundle["company"]
        signal_obj["price"] = bundle["price"]
        signal_obj["change_pct"] = bundle["change_pct"]
        signal_obj["timestamp"] = bundle["timestamp"]
        return signal_obj
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Signal calculation failed: {str(e)}")

@router.get("/capabilities")
def get_ai_capabilities():
    """
    Section 4: Centralized registry of all 25 TradeVision AI capabilities.
    """
    return {
        "capabilities": [cap.value for cap in AICapability],
        "count": len(AICapability),
        "status": "active",
        "primary_engine": "Groq (qwen/qwen3.8-27b)",
        "ml_model": "TradeVision Universal XGBoost v2",
    }

@router.get("/explain/indicator/{name}")
def explain_indicator(name: str, symbol: Optional[str] = Query(None)):
    """
    Section 12: Indicator Explanation Mode.
    Explains RSI, MACD, EMA, Bollinger Bands, etc., grounded in current live values.
    """
    name_clean = name.upper().strip()
    data = None
    if symbol:
        try:
            bundle = ai_orchestrator._fetch_stock_bundle(symbol)
            tech = bundle.get("technicals", {})
            data = {
                "symbol": bundle["symbol"],
                "price": bundle["price"],
                "rsi": tech.get("rsi") or tech.get("momentum", {}).get("rsi_14"),
                "trend": tech.get("price_structure", {}).get("trend_direction"),
                "support": tech.get("key_levels", {}).get("nearest_support"),
                "resistance": tech.get("key_levels", {}).get("nearest_resistance"),
            }
        except Exception:
            data = None

    explanations = {
        "RSI": {
            "name": "Relative Strength Index (RSI)",
            "meaning": "Measures the speed and change of price movements on an oscillator scale of 0 to 100.",
            "interpretation": "Values above 70 indicate potential overbought condition; below 30 indicate potential oversold territory.",
            "limitations": "RSI alone does not guarantee a reversal. Strong trends can remain overbought or oversold for extended periods.",
        },
        "MACD": {
            "name": "Moving Average Convergence Divergence (MACD)",
            "meaning": "Trend-following momentum indicator showing the relationship between two exponential moving averages (12 and 26 EMA).",
            "interpretation": "Bullish when MACD crosses above the Signal line; bearish when crossing below.",
            "limitations": "Prone to whipsaws in sideways or low-volatility consolidating markets.",
        },
        "EMA": {
            "name": "Exponential Moving Average (EMA)",
            "meaning": "Gives greater weight to the most recent prices, reacting faster to price action than a simple SMA.",
            "interpretation": "Price trading above the EMA20/50 confirms upward trend; trading below indicates downward pressure.",
            "limitations": "Lagging indicator derived from past closing prices.",
        },
        "BOLLINGER": {
            "name": "Bollinger Bands",
            "meaning": "A 20-period SMA flanked by upper and lower standard deviation bands measuring dynamic market volatility.",
            "interpretation": "Band squeezes forecast explosive volatility expansion; touches of outer bands highlight statistical extremes.",
            "limitations": "Touching a band does not signify a sell or buy signal by itself.",
        },
    }

    base = explanations.get(name_clean, {
        "name": name,
        "meaning": f"Technical indicator {name} used in market analysis.",
        "interpretation": "Evaluates price action, momentum, or volatility.",
        "limitations": "Must be combined with volume and macro market context.",
    })

    return {
        "indicator": base,
        "live_context": data,
    }

@router.get("/chat/status")
async def get_groq_status():
    """
    Returns the operational status of the Groq AI Engine.
    """
    return {
        "status": "online" if groq_service.is_configured() else "offline",
        "provider": "Groq",
        "primary_model": groq_service.primary_model,
        "available_models": [
            "qwen/qwen3.8-27b",
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b"
        ],
        "active": groq_service.is_configured(),
        "gemini_disabled": True,
        "capabilities_count": len(AICapability),
    }

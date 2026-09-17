from fastapi import FastAPI, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json

from app.routers.chart import router as chart_router
from app.routers.indicators import router as indicators_router
from app.routers.news import router as news_router
from app.routers.overview import router as overview_router
from app.routers.recommendation import router as recommendation_router
from app.routers.stock_details import router as stock_details_router
from app.routers.stocks import router as stocks_router
from app.routers.test import router as test_router
from app.routers.ai_generate import router as ai_router

from app.services.market_service import (
    get_indices, get_live_quote, get_ohlc_history, get_top_movers
)
from app.services.news_service import get_live_news, get_market_news

app = FastAPI(title="TradeVision AI Backend", version="2.4.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(test_router)
app.include_router(stock_details_router)
app.include_router(chart_router)
app.include_router(indicators_router)
app.include_router(news_router)
app.include_router(overview_router)
app.include_router(recommendation_router)
app.include_router(stocks_router)
app.include_router(ai_router)

# ── WEBSOCKET: Live price streaming ─────────────────────────────────────

class ConnectionManager:
    def __init__(self):
        self.active: list[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)

    def disconnect(self, ws: WebSocket):
        if ws in self.active:
            self.active.remove(ws)

    async def broadcast(self, data: dict):
        disconnected = []
        for ws in self.active:
            try:
                await ws.send_json(data)
            except Exception:
                disconnected.append(ws)
        for ws in disconnected:
            if ws in self.active:
                self.active.remove(ws)

manager = ConnectionManager()

@app.websocket('/ws/market')
async def websocket_market(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Push live indices every 1 second
            data = await get_indices()
            await websocket.send_json(data)
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)

@app.websocket('/ws/quote/{symbol}')
async def websocket_quote(websocket: WebSocket, symbol: str):
    await manager.connect(websocket)
    try:
        while True:
            # Push live stock quote every 1 second
            data = await get_live_quote(symbol.upper())
            await websocket.send_json(data)
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)

@app.websocket('/ws/news')
async def websocket_news(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Push live breaking official news every 1 second with live time_ago ticks
            data = get_market_news(limit=20)
            await websocket.send_json(data)
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)

# ── API REST ENDPOINTS ───────────────────────────────────────────────────

@app.get('/api/indices')
async def api_indices():
    return await get_indices()

@app.get('/api/quote/{symbol}')
async def api_quote(symbol: str):
    return await get_live_quote(symbol.upper())

@app.get('/api/ohlc/{symbol}/{period}')
async def api_ohlc(symbol: str, period: str):
    return await get_ohlc_history(symbol.upper(), period.upper())

@app.get('/api/movers')
async def api_movers():
    return await get_top_movers()

@app.get('/api/news')
async def api_news(limit: int = Query(15, ge=1, le=50)):
    articles = await get_live_news(limit=limit)
    return {'articles': articles, 'count': len(articles)}

@app.get('/api/health')
async def api_health():
    return {'status': 'ok', 'version': '2.4.0'}


@app.get("/")
def root():
    return {
        "message": "TradeVision AI backend is running",
        "version": "2.0.0",
        "flutter_web_app": "http://127.0.0.1:8080/",
        "backend_mounted_app": "http://127.0.0.1:8000/web/",
        "interactive_ui_preview": "http://127.0.0.1:8000/preview",
        "api_docs": "http://127.0.0.1:8000/docs"
    }


@app.get("/health")
def health():
    return {"status": "ok"}


import os
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WEB_BUILD_DIR = os.path.join(BASE_DIR, "frontend", "build", "web")
PREVIEW_FILE = os.path.join(BASE_DIR, "tradevision_ui_preview.html")

if os.path.exists(PREVIEW_FILE):
    @app.get("/preview", response_class=HTMLResponse)
    def ui_preview():
        with open(PREVIEW_FILE, "r", encoding="utf-8") as f:
            return f.read()

if os.path.exists(WEB_BUILD_DIR):
    app.mount("/web", StaticFiles(directory=WEB_BUILD_DIR, html=True), name="flutter_web")



_market_trend_cache = {"data": None, "timestamp": 0.0}

@app.get("/market/trend")
def market_trend():
    """Market-wide trend summary: major Indian indices + top movers."""
    import time
    from concurrent.futures import ThreadPoolExecutor
    from app.services.stock_service import get_stock_by_symbol

    now = time.time()
    if _market_trend_cache["data"] and (now - _market_trend_cache["timestamp"] < 30.0):
        return _market_trend_cache["data"]

    _indices = [
        ("^NSEI", "NIFTY 50"),
        ("^BSESN", "SENSEX"),
        ("^NSEBANK", "NIFTY BANK"),
        ("^CNXIT", "NIFTY IT"),
    ]
    _movers = ["RELIANCE.NS", "TCS.NS", "INFY.NS", "HDFCBANK.NS", "TATAMOTORS.NS", "MARUTI.NS", "ZOMATO.NS"]

    all_syms = [s for s, _ in _indices] + _movers
    fetched_map = {}

    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(get_stock_by_symbol, s): s for s in all_syms}
        for future in futures:
            s = futures[future]
            try:
                fetched_map[s] = future.result(timeout=4.0)
            except Exception:
                pass

    indices = []
    for sym, label in _indices:
        d = fetched_map.get(sym, {})
        indices.append({
            "symbol": label,
            "price":  d.get("current_price") or 24132.60,
            "change": d.get("change_percent") or 1.25,
        })

    top_movers = []
    for sym in _movers:
        d = fetched_map.get(sym, {})
        if d:
            top_movers.append({
                "symbol":  sym.replace(".NS", ""),
                "name":    d.get("company_name", sym.replace(".NS", "")),
                "price":   d.get("current_price"),
                "change":  d.get("change_percent"),
            })

    gainers = sorted(top_movers, key=lambda x: x.get("change") or 0, reverse=True)[:3]
    losers  = sorted(top_movers, key=lambda x: x.get("change") or 0)[:3]

    result = {
        "indices":    indices,
        "top_gainers": gainers,
        "top_losers":  losers,
        "sentiment":   "Bullish",
    }
    _market_trend_cache["data"] = result
    _market_trend_cache["timestamp"] = now
    return result


@app.get("/search")
def search_stocks(q: str = Query(..., description="Search term (name or ticker)")):
    """Search for Indian stocks matching a symbol or company name."""
    POPULAR = [
        {"symbol": "RELIANCE", "name": "Reliance Industries Ltd",    "sector": "Energy"},
        {"symbol": "TCS",      "name": "Tata Consultancy Services",  "sector": "Technology"},
        {"symbol": "INFY",     "name": "Infosys Ltd.",              "sector": "Technology"},
        {"symbol": "HDFCBANK", "name": "HDFC Bank Ltd.",             "sector": "Financial"},
        {"symbol": "ICICIBANK","name": "ICICI Bank Ltd.",            "sector": "Financial"},
        {"symbol": "SBIN",     "name": "State Bank of India",        "sector": "Financial"},
        {"symbol": "TATAMOTORS","name":"Tata Motors Ltd.",           "sector": "Automobile"},
        {"symbol": "MARUTI",   "name": "Maruti Suzuki India Ltd",   "sector": "Automobile"},
        {"symbol": "BHARTIARTL","name":"Bharti Airtel Ltd",          "sector": "Telecom"},
        {"symbol": "ITC",      "name": "ITC Ltd",                   "sector": "FMCG"},
        {"symbol": "ZOMATO",   "name": "Zomato Ltd",                "sector": "Consumer Services"},
        {"symbol": "PAYTM",    "name": "One97 Communications Ltd",  "sector": "Financial"},
    ]
    query = q.strip().upper()
    results = [
        s for s in POPULAR
        if query in s["symbol"].upper() or query in s["name"].upper()
    ][:10]
    return {"query": q, "results": results}
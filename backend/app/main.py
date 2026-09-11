from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from app.routers.chart import router as chart_router
from app.routers.indicators import router as indicators_router
from app.routers.news import router as news_router
from app.routers.overview import router as overview_router
from app.routers.recommendation import router as recommendation_router
from app.routers.stock_details import router as stock_details_router
from app.routers.stocks import router as stocks_router
from app.routers.test import router as test_router
from app.routers.ai_generate import router as ai_router

app = FastAPI(title="TradeVision AI Backend", version="2.0.0")

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



@app.get("/market/trend")
def market_trend():
    """Market-wide trend summary: major Indian indices + top movers."""
    from app.services.stock_service import get_stock_by_symbol

    _indices = [
        ("^NSEI", "NIFTY 50"),
        ("^BSESN", "SENSEX"),
        ("^NSEBANK", "NIFTY BANK"),
        ("^CNXIT", "NIFTY IT"),
    ]
    indices = []
    for sym, label in _indices:
        try:
            d = get_stock_by_symbol(sym)
            indices.append({
                "symbol": label,
                "price":  d.get("current_price") or 24132.60,
                "change": d.get("change_percent") or 1.25,
            })
        except Exception:
            indices.append({"symbol": label, "price": 24132.60, "change": 1.25})

    _movers = ["RELIANCE.NS", "TCS.NS", "INFY.NS", "HDFCBANK.NS", "TATAMOTORS.NS", "MARUTI.NS", "ZOMATO.NS"]
    top_movers = []
    for sym in _movers:
        try:
            d = get_stock_by_symbol(sym)
            top_movers.append({
                "symbol":  sym.replace(".NS", ""),
                "name":    d.get("company_name", sym.replace(".NS", "")),
                "price":   d.get("current_price"),
                "change":  d.get("change_percent"),
            })
        except Exception:
            pass

    gainers = sorted(top_movers, key=lambda x: x.get("change") or 0, reverse=True)[:3]
    losers  = sorted(top_movers, key=lambda x: x.get("change") or 0)[:3]

    return {
        "indices":    indices,
        "top_gainers": gainers,
        "top_losers":  losers,
        "sentiment":   "Bullish",
    }


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
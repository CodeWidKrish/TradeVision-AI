from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.chart import router as chart_router
from app.routers.indicators import router as indicators_router
from app.routers.news import router as news_router
from app.routers.overview import router as overview_router
from app.routers.recommendation import router as recommendation_router
from app.routers.stock_details import router as stock_details_router
from app.routers.stocks import router as stocks_router
from app.routers.test import router as test_router

app = FastAPI(title="TradeVision AI Backend")

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

@app.get("/")
def root():
    return {"message": "TradeVision AI backend is running"}

@app.get("/health")
def health():
    return {"status": "ok"}
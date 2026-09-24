import base64
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from pydantic import BaseModel
from app.services.report_service import generate_stock_research_report, analyze_chart_screenshot

router = APIRouter(prefix="/report", tags=["report"])

class Base64ChartAnalysisRequest(BaseModel):
    image_base64: str
    filename: Optional[str] = "chart.png"
    symbol: Optional[str] = None

@router.get("/stock/{symbol}")
def get_stock_report(symbol: str):
    """
    Generate an institutional, comprehensive AI stock research report
    for any Indian stock with live metrics and quantitative confidence.
    """
    try:
        return generate_stock_research_report(symbol)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

@router.post("/analyze-chart")
async def analyze_chart(
    file: Optional[UploadFile] = File(None),
    symbol: Optional[str] = Form(None)
):
    """
    Upload a stock chart screenshot for ML Computer Vision pattern analysis.
    """
    try:
        if file is None:
            raise HTTPException(status_code=400, detail="No image file provided.")
        contents = await file.read()
        return analyze_chart_screenshot(contents, filename=file.filename or "chart.png", symbol_hint=symbol)
    except ValueError as val_err:
        raise HTTPException(status_code=400, detail=str(val_err))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

@router.post("/analyze-chart-base64")
async def analyze_chart_base64(req: Base64ChartAnalysisRequest):
    """
    Analyze chart screenshot passed as base64 string (web/mobile friendly).
    """
    try:
        raw_b64 = req.image_base64
        if "," in raw_b64:
            raw_b64 = raw_b64.split(",", 1)[1]
        image_bytes = base64.b64decode(raw_b64)
        return analyze_chart_screenshot(image_bytes, filename=req.filename or "chart.png", symbol_hint=req.symbol)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Base64 analysis failed: {str(exc)}")

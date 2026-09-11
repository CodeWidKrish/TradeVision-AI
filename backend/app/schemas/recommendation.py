from pydantic import BaseModel
from typing import List, Optional

class RecommendationResponse(BaseModel):
    symbol: str
    decision: str          # buy | sell | hold
    confidence: float      # 0.0 – 1.0
    reason: str
    key_factors: List[str]
    rsi: Optional[float] = None
    macd: Optional[float] = None
    sentiment_score: Optional[float] = None
    disclaimer: str = "⚠️ AI-generated analysis for educational purposes only. Not financial advice."
    message: Optional[str] = "Recommendation loaded"
from pydantic import BaseModel
from typing import List, Optional

class RecommendationResponse(BaseModel):
    symbol: str
    decision: str
    confidence: float
    reason: str
    key_factors: List[str]
    message: Optional[str] = "Recommendation loaded"
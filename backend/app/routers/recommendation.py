from fastapi import APIRouter
from app.schemas.recommendation import RecommendationResponse
from app.services.recommendation_service import get_recommendation_by_symbol

router = APIRouter(prefix="/recommendation", tags=["recommendation"])

@router.get("/{symbol}", response_model=RecommendationResponse)
def get_recommendation(symbol: str):
    return get_recommendation_by_symbol(symbol)
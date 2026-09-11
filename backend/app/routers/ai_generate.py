from fastapi import APIRouter, HTTPException, Depends
from app.schemas.ai_schemas import AIGenerateRequest, AIGenerateResponse, AITemplateResponse
from app.services.ai_service import AIService
from typing import List

router = APIRouter(prefix="/ai", tags=["AI UI Generation"])

# Initialize service as a dependency or a singleton
ai_service = AIService()

def get_ai_service():
    return ai_service

@router.post("/generate", response_model=AIGenerateResponse)
async def generate_ui(request: AIGenerateRequest, service: AIService = Depends(get_ai_service)):
    """
    Generates premium Flutter/Dart code from a text description using
    Wizcoderr/Qwen3-14B-Flutter-Fused model with fallback support.
    """
    try:
        if not request.prompt.strip():
            raise HTTPException(status_code=400, detail="Prompt cannot be empty")
            
        generated_code = await service.generate_code(
            prompt=request.prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature
        )
        
        # Estimate token usage roughly (4 chars ~ 1 token)
        estimated_tokens = len(generated_code) // 4
        
        return AIGenerateResponse(
            code=generated_code,
            model=service.model_id,
            tokens_used=estimated_tokens
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")

@router.get("/health")
def check_ai_health(service: AIService = Depends(get_ai_service)):
    """
    Returns the health and configuration status of the AI Inference Service.
    """
    configured = service.is_configured()
    return {
        "status": "healthy",
        "live_inference": configured,
        "model": service.model_id,
        "message": (
            "Connected to live Hugging Face API." if configured 
            else "Running in fallback mode. Pre-built premium layouts will be served."
        )
    }

@router.get("/templates", response_model=List[AITemplateResponse])
def get_templates():
    """
    Returns a collection of prompt templates for generating premium stock trading dashboards.
    """
    return [
        AITemplateResponse(
            name="Stock Market Dashboard",
            description="A modern, dark-themed responsive dashboard with glassmorphism cards and metrics.",
            prompt=(
                "Create a premium stock market dashboard in Flutter.\n"
                "Requirements:\n"
                "- Material 3 styling\n"
                "- Sleek dark theme\n"
                "- Glassmorphism card elements\n"
                "- Portfolio net worth card and trending assets grid"
              )
        ),
        AITemplateResponse(
            name="Glassmorphic Stock Chart",
            description="A premium card that visualizes price trends with a custom-painted glass line chart.",
            prompt=(
                "Create a premium custom stock price chart card in Flutter.\n"
                "Requirements:\n"
                "- Glassmorphism effects with BackdropFilter blur\n"
                "- CustomPainter for a smooth neon-glow line chart with gradient fill below the path\n"
                "- Price metric header, percentage change tag, and timeframe selector chips"
            )
        ),
        AITemplateResponse(
            name="AI Chat Assistant",
            description="A sleek assistant interface with user/bot speech bubbles and an input field.",
            prompt=(
                "Create a premium AI Chat Assistant UI in Flutter.\n"
                "- Modern conversational bubble design with distinct colors for user and assistant\n"
                "- Input message textfield with rounded corners, send icon button\n"
                "- Header with status indicator ('Online • Powered by Qwen & FinBERT')"
            )
        ),
        AITemplateResponse(
            name="Crypto Tracker Card",
            description="A modern, compact card for tracking cryptocurrencies with a mini trendline.",
            prompt=(
                "Create a responsive crypto currency tracking card in Flutter.\n"
                "- Show ticker symbol (e.g. BTC/USDT), logo placeholder, live price, and daily change\n"
                "- Mini chart path showing trend direction\n"
                "- Rounded border with premium dark gradient background"
            )
        )
    ]

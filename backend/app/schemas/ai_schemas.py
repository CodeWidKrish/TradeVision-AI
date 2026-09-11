from pydantic import BaseModel, Field
from typing import List, Optional

class AIGenerateRequest(BaseModel):
    prompt: str = Field(..., description="Description of the Flutter screen/widget to generate")
    max_tokens: int = Field(2048, description="Maximum number of tokens to generate")
    temperature: float = Field(0.7, description="Sampling temperature (0.0 to 1.0)")

class AIGenerateResponse(BaseModel):
    code: str = Field(..., description="Generated Dart/Flutter code")
    model: str = Field("Wizcoderr/Qwen3-14B-Flutter-Fused", description="Model name used for generation")
    tokens_used: Optional[int] = Field(None, description="Number of tokens consumed")

class AITemplateResponse(BaseModel):
    name: str = Field(..., description="Name of the template")
    description: str = Field(..., description="Short description of the template")
    prompt: str = Field(..., description="Pre-filled prompt text")

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class PredictionResult(BaseModel):
    disease: str
    confidence: float = Field(ge=0.0, le=1.0)
    plant: str
    description: str
    treatment: list[str]
    prevention: list[str]
    is_healthy: bool = False
    class_label: str | None = None


class DetectResponse(BaseModel):
    success: bool = True
    prediction: PredictionResult


class LegacyPredictResponse(BaseModel):
    """Backward-compatible shape for the existing Flutter client."""

    disease: str
    confidence: float
    plant: str | None = None
    isHealthy: bool = False
    recommendations: list[str] = Field(default_factory=list)
    description: str | None = None
    top_predictions: list[dict[str, Any]] | None = None


class DetectionHistoryItem(BaseModel):
    id: int
    plant_name: str | None
    disease_name: str | None
    confidence: float
    image_path: str
    created_at: datetime
    prediction: PredictionResult | None = None

    model_config = {"from_attributes": True}


class DetectionDetailResponse(BaseModel):
    success: bool = True
    detection: DetectionHistoryItem

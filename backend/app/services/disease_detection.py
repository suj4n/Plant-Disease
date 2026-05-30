from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.models import load_model

from app.core.config import Settings, get_settings
from app.core.exceptions import InferenceError
from app.data.disease_metadata import build_metadata_for_label
from app.schemas.detection import PredictionResult

logger = logging.getLogger(__name__)


@dataclass
class TopPrediction:
    class_label: str
    confidence: float
    plant: str
    disease: str


class DiseaseDetectionService:
    """Loads the Keras model once and runs plant disease inference."""

    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self._model = None
        self._class_names: list[str] = []

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self) -> None:
        model_path = self.settings.model_path
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found at {model_path}")

        labels_path = self.settings.class_names_path
        if not labels_path.exists():
            raise FileNotFoundError(f"Class names not found at {labels_path}")

        with labels_path.open(encoding="utf-8") as f:
            self._class_names = json.load(f)

        logger.info("Loading Keras model from %s", model_path)
        self._model = load_model(model_path, compile=False)
        logger.info("Model loaded. Classes: %d", len(self._class_names))

    def preprocess(self, image_rgb: np.ndarray) -> np.ndarray:
        """Resize to 224x224 and apply MobileNetV2 preprocessing."""
        import cv2

        size = self.settings.model_input_size
        resized = cv2.resize(image_rgb, (size, size), interpolation=cv2.INTER_AREA)
        batch = np.expand_dims(resized.astype(np.float32), axis=0)
        return preprocess_input(batch)

    def predict(self, image_rgb: np.ndarray, top_k: int = 5) -> tuple[PredictionResult, list[TopPrediction]]:
        if self._model is None:
            raise InferenceError("Model is not loaded")

        batch = self.preprocess(image_rgb)
        try:
            probs = self._model.predict(batch, verbose=0)[0]
        except Exception as exc:
            logger.exception("Inference failed")
            raise InferenceError(str(exc)) from exc

        top_indices = np.argsort(probs)[::-1][:top_k]
        tops: list[TopPrediction] = []
        for idx in top_indices:
            label = self._class_names[int(idx)]
            meta = build_metadata_for_label(label)
            tops.append(
                TopPrediction(
                    class_label=label,
                    confidence=float(probs[idx]),
                    plant=meta["plant"],
                    disease=meta["disease"],
                )
            )

        best = tops[0]
        meta = build_metadata_for_label(best.class_label)
        result = PredictionResult(
            disease=meta["disease"],
            confidence=round(best.confidence, 4),
            plant=meta["plant"],
            description=meta["description"],
            treatment=meta["treatment"],
            prevention=meta["prevention"],
            is_healthy=meta.get("is_healthy", False),
            class_label=best.class_label,
        )
        return result, tops

    def to_legacy_response(
        self,
        prediction: PredictionResult,
        tops: list[TopPrediction],
    ) -> dict[str, Any]:
        recommendations = prediction.treatment + prediction.prevention
        return {
            "disease": prediction.disease,
            "confidence": prediction.confidence,
            "plant": prediction.plant,
            "isHealthy": prediction.is_healthy,
            "recommendations": recommendations[:8],
            "description": prediction.description,
            "top_predictions": [
                {
                    "class": t.class_label,
                    "disease": t.disease,
                    "plant": t.plant,
                    "confidence": round(t.confidence, 4),
                }
                for t in tops
            ],
        }


_detection_service: DiseaseDetectionService | None = None


def get_detection_service() -> DiseaseDetectionService:
    global _detection_service
    if _detection_service is None:
        _detection_service = DiseaseDetectionService()
    return _detection_service

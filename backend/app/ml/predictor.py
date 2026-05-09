from __future__ import annotations

import io
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

from ..labels import CLASS_NAMES


@dataclass(frozen=True)
class Prediction:
    label: str
    probability: float


class Predictor:
    def __init__(self, model_path: str):
        self._model_path = str(model_path)
        self._model: Any | None = None

    @property
    def model_path(self) -> str:
        return self._model_path

    @staticmethod
    def _resolve_model_path(model_path: str) -> Path:
        p = Path(model_path)
        if p.is_absolute():
            return p

        # Resolve relative paths against the backend/ folder, not the current working directory.
        # This makes running uvicorn from repo root (or elsewhere) work reliably.
        backend_dir = Path(__file__).resolve().parents[2]  # backend/
        return (backend_dir / p).resolve()

    def _load_model(self) -> Any:
        if self._model is not None:
            return self._model

        try:
            import tensorflow as tf  # type: ignore
        except Exception as e:  # pragma: no cover
            raise RuntimeError(
                "TensorFlow is not installed (or not supported by your Python version). "
                "Use Python 3.11/3.12 and install backend/requirements.txt."
            ) from e

        resolved = self._resolve_model_path(self._model_path)
        if not resolved.exists():
            raise RuntimeError(f"Model not found at: {resolved}")

        self._model = tf.keras.models.load_model(resolved)
        self._model_path = str(resolved)
        return self._model

    @staticmethod
    def _preprocess_image(file_bytes: bytes) -> np.ndarray:
        # The training notebook used image_size=(160,160) and the model includes rescaling.
        img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
        img = img.resize((160, 160), Image.BILINEAR)
        arr = np.asarray(img, dtype=np.float32)  # keep [0..255]
        arr = np.expand_dims(arr, axis=0)  # (1,160,160,3)
        return arr

    def predict(self, file_bytes: bytes, top_k: int) -> list[Prediction]:
        model = self._load_model()
        x = self._preprocess_image(file_bytes)

        probs = model.predict(x, verbose=0)[0]
        probs = np.asarray(probs, dtype=np.float32)

        if probs.ndim != 1:
            probs = probs.reshape(-1)

        k = max(1, min(int(top_k), len(probs)))
        idx = np.argsort(probs)[::-1][:k]

        out: list[Prediction] = []
        for i in idx:
            label = CLASS_NAMES[int(i)] if int(i) < len(CLASS_NAMES) else f"class_{int(i)}"
            out.append(Prediction(label=label, probability=float(probs[int(i)])))
        return out


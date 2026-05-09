from __future__ import annotations

import io
import logging
from contextlib import asynccontextmanager
from dataclasses import asdict

from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, UnidentifiedImageError

from .labels import CLASS_NAMES
from .ml.predictor import Predictor
from .settings import settings

logger = logging.getLogger("backend")

def _parse_allow_origins(value: str) -> list[str]:
    v = (value or "").strip()
    if not v or v == "*":
        return ["*"]
    return [o.strip() for o in v.split(",") if o.strip()]


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Keep the predictor as app state to avoid module-level side effects.
    predictor = Predictor(model_path=settings.model_path)
    app.state.predictor = predictor

    if settings.preload_model:
        logger.info("Preloading model from %s", settings.model_path)
        predictor._load_model()

    yield


app = FastAPI(title="Plant Disease Backend", version="0.2.0", lifespan=lifespan)

allow_origins = _parse_allow_origins(settings.allow_origins)
app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    # Browsers reject credentialed requests with wildcard origin. Make it safe by default.
    allow_credentials=(allow_origins != ["*"]),
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/meta")
def meta():
    return {
        "classes": CLASS_NAMES,
        "num_classes": len(CLASS_NAMES),
        "default_top_k": settings.default_top_k,
    }


@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    top_k: int | None = Query(default=None, ge=1, description="Number of top predictions to return"),
):
    payload = await file.read()
    if not payload:
        raise HTTPException(status_code=400, detail="Empty file.")
    if len(payload) > int(settings.max_upload_bytes):
        raise HTTPException(status_code=413, detail="File too large.")

    # Some mobile clients upload valid images with a generic content-type like
    # application/octet-stream. Validate by decoding instead of trusting headers.
    try:
        img = Image.open(io.BytesIO(payload))
        img.verify()
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status_code=415, detail="Upload an image file (content-type image/*).")

    k = int(top_k) if top_k is not None else int(settings.default_top_k)

    try:
        preds = app.state.predictor.predict(payload, top_k=k)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference failed: {e}")

    return {
        "top_label": preds[0].label if preds else None,
        "predictions": [asdict(p) for p in preds],
        "model_path": app.state.predictor.model_path,
    }


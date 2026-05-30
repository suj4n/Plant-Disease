import json
from pathlib import Path

from fastapi import APIRouter, File, Query, UploadFile

from app.api.dependencies.auth import DbSession, OptionalUser
from app.core.config import get_settings
from app.core.exceptions import AppException
from app.models.detection import Detection
from app.schemas.detection import DetectResponse, LegacyPredictResponse
from app.services.disease_detection import get_detection_service
from app.utils.image import load_image_rgb, validate_image_bytes

router = APIRouter(tags=["detection"])
legacy_router = APIRouter(tags=["legacy"])


async def _read_upload(file: UploadFile) -> bytes:
    settings = get_settings()
    if file.content_type and file.content_type not in {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/bmp",
        "application/octet-stream",
    }:
        raise AppException(f"Unsupported content type: {file.content_type}", status_code=400)
    data = await file.read()
    validate_image_bytes(data, settings.max_upload_size_mb)
    return data


@router.post("/detect", response_model=DetectResponse)
async def detect_disease(
    db: DbSession,
    current_user: OptionalUser,
    file: UploadFile = File(...),
) -> DetectResponse:
    settings = get_settings()
    data = await _read_upload(file)
    rgb = load_image_rgb(data)

    service = get_detection_service()
    prediction, _tops = service.predict(rgb)

    suffix = Path(file.filename or "upload.jpg").suffix or ".jpg"
    from datetime import datetime, timezone

    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    image_path = settings.upload_dir / f"{stamp}{suffix}"
    image_path.write_bytes(data)

    if current_user:
        record = Detection(
            user_id=current_user.id,
            image_path=str(image_path.relative_to(settings.upload_dir.parent)),
            plant_name=prediction.plant,
            disease_name=prediction.disease,
            confidence=prediction.confidence,
            result_json=prediction.model_dump_json(),
        )
        db.add(record)
        db.commit()

    return DetectResponse(prediction=prediction)


@legacy_router.post("/predict", response_model=LegacyPredictResponse)
async def predict_legacy(
    db: DbSession,
    current_user: OptionalUser,
    file: UploadFile = File(...),
    top_k: int = Query(5, ge=1, le=20),
) -> LegacyPredictResponse:
    """Legacy endpoint for the existing Flutter client (`/predict`)."""
    settings = get_settings()
    data = await _read_upload(file)
    rgb = load_image_rgb(data)

    service = get_detection_service()
    prediction, tops = service.predict(rgb, top_k=top_k)
    legacy = service.to_legacy_response(prediction, tops)

    suffix = Path(file.filename or "upload.jpg").suffix or ".jpg"
    from datetime import datetime, timezone

    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    image_path = settings.upload_dir / f"{stamp}{suffix}"
    image_path.write_bytes(data)

    if current_user:
        record = Detection(
            user_id=current_user.id,
            image_path=str(image_path.relative_to(settings.upload_dir.parent)),
            plant_name=prediction.plant,
            disease_name=prediction.disease,
            confidence=prediction.confidence,
            result_json=json.dumps(legacy),
        )
        db.add(record)
        db.commit()

    return LegacyPredictResponse(**legacy)

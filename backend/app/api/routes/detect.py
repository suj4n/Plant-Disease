"""Disease detection routes.

Both the versioned `/api/v1/detect` and the legacy `/predict` run through the same
`_run_detection` / `_persist_detection` pair. They differ only in how the result is
serialised, so there is exactly one inference and one persistence implementation.
"""

import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, File, Query, UploadFile

from app.api.dependencies.auth import DbSession, OptionalUser
from app.core.config import get_settings
from app.core.exceptions import InvalidImageError
from app.models.detection import Detection
from app.models.user import User
from app.schemas.detection import (
    AlternativePrediction,
    DetectionInformation,
    DetectionMetadata,
    DetectResponse,
    LegacyPredictResponse,
    PredictionResult,
)
from app.services.disease_detection import TopPrediction, get_detection_service
from app.utils.image import ALLOWED_CONTENT_TYPES, load_image_rgb, validate_image_bytes

logger = logging.getLogger(__name__)

router = APIRouter(tags=["detection"])
legacy_router = APIRouter(tags=["legacy"])

#: Alternatives shown to the user, beyond the primary prediction.
MAX_ALTERNATIVES = 4

ERROR_RESPONSES = {
    400: {"description": "INVALID_IMAGE - the upload is not a readable image."},
    413: {"description": "FILE_TOO_LARGE - the upload exceeds the size limit."},
    503: {"description": "MODEL_UNAVAILABLE / PREDICTION_FAILED."},
}


async def _read_upload(file: UploadFile) -> bytes:
    settings = get_settings()
    if file.content_type and file.content_type not in (
        ALLOWED_CONTENT_TYPES | {"application/octet-stream"}
    ):
        raise InvalidImageError(f"Unsupported content type: {file.content_type}")
    data = await file.read()
    validate_image_bytes(data, settings.max_upload_size_mb)
    return data


async def _run_detection(
    file: UploadFile,
    top_k: int,
) -> tuple[bytes, PredictionResult, list[TopPrediction], int]:
    data = await _read_upload(file)
    rgb = load_image_rgb(data)
    prediction, tops, elapsed_ms = get_detection_service().predict(rgb, top_k=top_k)
    return data, prediction, tops, elapsed_ms


def _persist_detection(
    db: DbSession,
    user: User | None,
    data: bytes,
    prediction: PredictionResult,
    result_json: str,
    image_format: str,
) -> None:
    """Store the image and the detection row — only for an authenticated user.

    Anonymous scans are not written to disk at all, so `uploads/` no longer grows
    without bound. The extension comes from the *decoded* image format, never from
    the client-supplied filename.
    """
    if user is None:
        return

    settings = get_settings()
    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    image_path = settings.upload_dir / f"{stamp}.{image_format}"
    image_path.write_bytes(data)

    db.add(
        Detection(
            user_id=user.id,
            image_path=str(image_path.relative_to(settings.upload_dir.parent)),
            plant_name=prediction.plant,
            disease_name=prediction.disease,
            confidence=prediction.confidence,
            result_json=result_json,
        )
    )
    db.commit()


@router.post(
    "/detect",
    response_model=DetectResponse,
    summary="Detect plant disease from a leaf photo",
    description=(
        "Runs the MobileNetV2 classifier over an uploaded leaf image and returns the "
        "most likely class, up to four alternatives, treatment information and "
        "inference metadata. Accepts JPEG, PNG, WebP and BMP up to the configured "
        "size limit. When `prediction.is_identifiable` is false no leaf was found and "
        "the client should ask for a clearer photo rather than show a diagnosis."
    ),
    responses=ERROR_RESPONSES,
)
async def detect_disease(
    db: DbSession,
    current_user: OptionalUser,
    file: UploadFile = File(..., description="Leaf photo to analyse."),
    top_k: int = Query(5, ge=1, le=20, description="Number of classes to rank."),
) -> DetectResponse:
    data, prediction, tops, elapsed_ms = await _run_detection(file, top_k)

    alternatives = [
        AlternativePrediction(
            disease=t.disease,
            plant=t.plant,
            confidence=round(t.confidence, 4),
            class_label=t.class_label,
        )
        for t in tops[1 : 1 + MAX_ALTERNATIVES]
    ]

    response = DetectResponse(
        prediction=prediction,
        alternatives=alternatives,
        information=DetectionInformation(
            description=prediction.description,
            symptoms=prediction.symptoms,
            treatment=prediction.treatment,
            prevention=prediction.prevention,
        ),
        metadata=DetectionMetadata(
            model_version=get_detection_service().model_version,
            processing_time_ms=elapsed_ms,
        ),
    )

    _persist_detection(
        db,
        current_user,
        data,
        prediction,
        prediction.model_dump_json(),
        _detected_format(data),
    )
    return response


@legacy_router.post(
    "/predict",
    response_model=LegacyPredictResponse,
    summary="Detect plant disease (legacy response shape)",
    description=(
        "Compatibility endpoint for existing Flutter clients. New clients should use "
        "`POST /api/v1/detect`, which returns structured symptoms, risk level and "
        "alternatives. Inference is identical — only the response shape differs."
    ),
    responses=ERROR_RESPONSES,
    deprecated=True,
)
async def predict_legacy(
    db: DbSession,
    current_user: OptionalUser,
    file: UploadFile = File(...),
    top_k: int = Query(5, ge=1, le=20),
) -> LegacyPredictResponse:
    data, prediction, tops, _elapsed_ms = await _run_detection(file, top_k)
    legacy = get_detection_service().to_legacy_response(prediction, tops)

    _persist_detection(
        db,
        current_user,
        data,
        prediction,
        json.dumps(legacy),
        _detected_format(data),
    )
    return LegacyPredictResponse(**legacy)


def _detected_format(data: bytes) -> str:
    """File extension derived from the decoded image, not the client's filename."""
    import io

    from PIL import Image

    try:
        fmt = Image.open(io.BytesIO(data)).format
    except Exception:  # already validated upstream; fall back rather than fail a scan
        return "jpg"
    return {"JPEG": "jpg", "PNG": "png", "WEBP": "webp", "BMP": "bmp"}.get(
        fmt or "", "jpg"
    )

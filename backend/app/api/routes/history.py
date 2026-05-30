import json

from fastapi import APIRouter

from app.api.dependencies.auth import CurrentUser, DbSession
from app.core.exceptions import NotFoundError
from app.models.detection import Detection
from app.schemas.common import MessageResponse
from app.schemas.detection import DetectionDetailResponse, DetectionHistoryItem, PredictionResult

router = APIRouter(prefix="/history", tags=["history"])


def _to_history_item(record: Detection) -> DetectionHistoryItem:
    prediction = None
    try:
        data = json.loads(record.result_json)
        if "disease" in data and "confidence" in data:
            if "prediction" in data:
                prediction = PredictionResult.model_validate(data["prediction"])
            elif "treatment" in data or "recommendations" in data:
                prediction = PredictionResult(
                    disease=data.get("disease", record.disease_name or "Unknown"),
                    confidence=float(data.get("confidence", record.confidence)),
                    plant=data.get("plant", record.plant_name or "Unknown"),
                    description=data.get("description", ""),
                    treatment=data.get("treatment") or data.get("recommendations", []),
                    prevention=data.get("prevention", []),
                    is_healthy=data.get("isHealthy", data.get("is_healthy", False)),
                )
            else:
                prediction = PredictionResult.model_validate(data)
    except Exception:
        prediction = None

    return DetectionHistoryItem(
        id=record.id,
        plant_name=record.plant_name,
        disease_name=record.disease_name,
        confidence=record.confidence,
        image_path=record.image_path,
        created_at=record.created_at,
        prediction=prediction,
    )


@router.get("", response_model=dict)
def list_history(current_user: CurrentUser, db: DbSession) -> dict:
    records = (
        db.query(Detection)
        .filter(Detection.user_id == current_user.id)
        .order_by(Detection.created_at.desc())
        .all()
    )
    return {
        "success": True,
        "history": [_to_history_item(r) for r in records],
    }


@router.get("/{detection_id}", response_model=DetectionDetailResponse)
def get_history_item(
    detection_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> DetectionDetailResponse:
    record = (
        db.query(Detection)
        .filter(Detection.id == detection_id, Detection.user_id == current_user.id)
        .first()
    )
    if not record:
        raise NotFoundError("Detection not found")
    return DetectionDetailResponse(detection=_to_history_item(record))


@router.delete("/{detection_id}", response_model=MessageResponse)
def delete_history_item(
    detection_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> MessageResponse:
    record = (
        db.query(Detection)
        .filter(Detection.id == detection_id, Detection.user_id == current_user.id)
        .first()
    )
    if not record:
        raise NotFoundError("Detection not found")
    db.delete(record)
    db.commit()
    return MessageResponse(message="Detection deleted")

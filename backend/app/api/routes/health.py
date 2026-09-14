import logging

from fastapi import APIRouter
from sqlalchemy import text

from app.api.dependencies.auth import DbSession
from app.schemas.common import HealthResponse
from app.services.disease_detection import get_detection_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Service health",
    description=(
        "Reports API, model and database readiness. Always returns 200 so that the "
        "probe itself is never mistaken for an outage; read `status` to distinguish "
        "`healthy` from `degraded`. Exposes no configuration or secrets."
    ),
)
def health_check(db: DbSession) -> HealthResponse:
    service = get_detection_service()

    try:
        db.execute(text("SELECT 1"))
        database = "connected"
    except Exception:
        logger.exception("Health check: database unreachable")
        database = "unavailable"

    model_loaded = service.is_loaded
    return HealthResponse(
        status="healthy" if (model_loaded and database == "connected") else "degraded",
        model_loaded=model_loaded,
        model_version=service.model_version if model_loaded else None,
        classes=service.class_count if model_loaded else 0,
        database=database,
    )

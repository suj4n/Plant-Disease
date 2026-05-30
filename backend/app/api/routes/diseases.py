from fastapi import APIRouter

from app.api.dependencies.auth import DbSession
from app.core.exceptions import NotFoundError
from app.models.disease import Disease
from app.schemas.disease import DiseaseListResponse, DiseaseRead

router = APIRouter(prefix="/diseases", tags=["diseases"])


@router.get("", response_model=DiseaseListResponse)
def list_diseases(db: DbSession) -> DiseaseListResponse:
    diseases = db.query(Disease).order_by(Disease.name).all()
    return DiseaseListResponse(diseases=[DiseaseRead.model_validate(d) for d in diseases])


@router.get("/{disease_id}", response_model=dict)
def get_disease(disease_id: int, db: DbSession) -> dict:
    disease = db.query(Disease).filter(Disease.id == disease_id).first()
    if not disease:
        raise NotFoundError("Disease not found")
    return {"success": True, "disease": DiseaseRead.model_validate(disease)}

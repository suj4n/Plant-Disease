from fastapi import APIRouter

from app.api.dependencies.auth import DbSession
from app.core.exceptions import NotFoundError
from app.models.plant import Plant
from app.schemas.plant import PlantListResponse, PlantRead

router = APIRouter(prefix="/plants", tags=["plants"])


@router.get("", response_model=PlantListResponse)
def list_plants(db: DbSession) -> PlantListResponse:
    plants = db.query(Plant).order_by(Plant.name).all()
    return PlantListResponse(plants=[PlantRead.model_validate(p) for p in plants])


@router.get("/{plant_id}", response_model=dict)
def get_plant(plant_id: int, db: DbSession) -> dict:
    plant = db.query(Plant).filter(Plant.id == plant_id).first()
    if not plant:
        raise NotFoundError("Plant not found")
    return {"success": True, "plant": PlantRead.model_validate(plant)}

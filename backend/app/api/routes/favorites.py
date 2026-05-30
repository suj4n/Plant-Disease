from fastapi import APIRouter

from app.api.dependencies.auth import CurrentUser, DbSession
from app.core.exceptions import AppException, NotFoundError
from app.models.disease import Disease
from app.models.detection import Detection
from app.models.favorite import Favorite
from app.models.plant import Plant
from app.schemas.common import MessageResponse
from app.schemas.favorite import FavoriteCreate, FavoriteListResponse, FavoriteRead

router = APIRouter(prefix="/favorites", tags=["favorites"])


def _validate_favorite_target(db: DbSession, item_type: str, item_id: int, user_id: int) -> None:
    if item_type == "plant":
        if not db.query(Plant).filter(Plant.id == item_id).first():
            raise NotFoundError("Plant not found")
    elif item_type == "disease":
        if not db.query(Disease).filter(Disease.id == item_id).first():
            raise NotFoundError("Disease not found")
    elif item_type == "detection":
        det = db.query(Detection).filter(Detection.id == item_id).first()
        if not det or det.user_id != user_id:
            raise NotFoundError("Detection not found")
    else:
        raise AppException("Invalid item_type")


@router.post("", response_model=dict, status_code=201)
def add_favorite(
    payload: FavoriteCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> dict:
    item_type = payload.item_type.value
    _validate_favorite_target(db, item_type, payload.item_id, current_user.id)

    existing = (
        db.query(Favorite)
        .filter(
            Favorite.user_id == current_user.id,
            Favorite.item_type == item_type,
            Favorite.item_id == payload.item_id,
        )
        .first()
    )
    if existing:
        raise AppException("Already in favorites", status_code=409)

    fav = Favorite(
        user_id=current_user.id,
        item_type=item_type,
        item_id=payload.item_id,
    )
    db.add(fav)
    db.commit()
    db.refresh(fav)
    return {"success": True, "favorite": FavoriteRead.model_validate(fav)}


@router.get("", response_model=FavoriteListResponse)
def list_favorites(current_user: CurrentUser, db: DbSession) -> FavoriteListResponse:
    favorites = (
        db.query(Favorite)
        .filter(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
        .all()
    )
    return FavoriteListResponse(
        favorites=[FavoriteRead.model_validate(f) for f in favorites],
    )


@router.delete("/{favorite_id}", response_model=MessageResponse)
def delete_favorite(
    favorite_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> MessageResponse:
    fav = (
        db.query(Favorite)
        .filter(Favorite.id == favorite_id, Favorite.user_id == current_user.id)
        .first()
    )
    if not fav:
        raise NotFoundError("Favorite not found")
    db.delete(fav)
    db.commit()
    return MessageResponse(message="Favorite removed")

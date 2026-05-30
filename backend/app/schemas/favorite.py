from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class FavoriteItemTypeSchema(str, Enum):
    plant = "plant"
    disease = "disease"
    detection = "detection"


class FavoriteCreate(BaseModel):
    item_type: FavoriteItemTypeSchema
    item_id: int = Field(gt=0)


class FavoriteRead(BaseModel):
    id: int
    item_type: FavoriteItemTypeSchema
    item_id: int
    created_at: datetime

    model_config = {"from_attributes": True}


class FavoriteListResponse(BaseModel):
    success: bool = True
    favorites: list[FavoriteRead]

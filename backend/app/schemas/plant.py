from pydantic import BaseModel


class PlantBase(BaseModel):
    name: str
    scientific_name: str | None = None
    description: str | None = None
    care_tips: str | None = None


class PlantRead(PlantBase):
    id: int

    model_config = {"from_attributes": True}


class PlantListResponse(BaseModel):
    success: bool = True
    plants: list[PlantRead]

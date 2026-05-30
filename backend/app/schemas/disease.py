from pydantic import BaseModel


class DiseaseBase(BaseModel):
    name: str
    description: str | None = None
    symptoms: str | None = None
    causes: str | None = None
    treatment: str | None = None
    prevention: str | None = None


class DiseaseRead(DiseaseBase):
    id: int

    model_config = {"from_attributes": True}

    @property
    def treatment_list(self) -> list[str]:
        return _split_lines(self.treatment)

    @property
    def prevention_list(self) -> list[str]:
        return _split_lines(self.prevention)


def _split_lines(value: str | None) -> list[str]:
    if not value:
        return []
    return [line.strip() for line in value.split("\n") if line.strip()]


class DiseaseListResponse(BaseModel):
    success: bool = True
    diseases: list[DiseaseRead]

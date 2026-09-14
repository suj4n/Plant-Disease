from pydantic import BaseModel


class MessageResponse(BaseModel):
    success: bool = True
    message: str | None = None


class HealthResponse(BaseModel):
    status: str = "healthy"
    model_loaded: bool = False
    model_version: str | None = None
    classes: int = 0
    database: str = "unknown"

    # ``model_`` is a protected prefix in pydantic v2 namespaces.
    model_config = {"protected_namespaces": ()}

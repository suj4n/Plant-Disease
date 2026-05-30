from typing import Any, Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str | None = None
    data: T | None = None


class ErrorResponse(BaseModel):
    success: bool = False
    message: str


class MessageResponse(BaseModel):
    success: bool = True
    message: str | None = None


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class PaginatedMeta(BaseModel):
    total: int


class HealthResponse(BaseModel):
    status: str = "healthy"

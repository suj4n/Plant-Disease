from fastapi import APIRouter

from app.api.dependencies.auth import CurrentUser, DbSession
from app.core.exceptions import AuthenticationError
from app.core.security import create_access_token, decode_token, verify_token_type
from app.schemas.auth import (
    AuthResponse,
    RefreshTokenRequest,
    TokenResponse,
    UserLogin,
    UserPublic,
    UserRegister,
)
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=201)
def register(payload: UserRegister, db: DbSession) -> AuthResponse:
    user = auth_service.register_user(db, payload)
    tokens = auth_service.issue_tokens(user)
    return AuthResponse(
        user=UserPublic.model_validate(user),
        tokens=TokenResponse(**tokens),
    )


@router.post("/login", response_model=AuthResponse)
def login(payload: UserLogin, db: DbSession) -> AuthResponse:
    user = auth_service.authenticate_user(db, payload.email, payload.password)
    tokens = auth_service.issue_tokens(user)
    return AuthResponse(
        user=UserPublic.model_validate(user),
        tokens=TokenResponse(**tokens),
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(payload: RefreshTokenRequest) -> TokenResponse:
    try:
        token_payload = decode_token(payload.refresh_token)
        verify_token_type(token_payload, "refresh")
        user_id = token_payload["sub"]
    except Exception as exc:
        raise AuthenticationError("Invalid refresh token") from exc

    access = create_access_token(str(user_id))
    return TokenResponse(
        access_token=access,
        refresh_token=payload.refresh_token,
        token_type="bearer",
    )


@router.get("/me", response_model=UserPublic)
def me(current_user: CurrentUser) -> UserPublic:
    return UserPublic.model_validate(current_user)

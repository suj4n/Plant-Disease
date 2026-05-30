from typing import Annotated

from fastapi import Depends, Header
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.exceptions import AuthenticationError
from app.core.security import decode_token, verify_token_type
from app.database.session import get_db
from app.models.user import User

DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    db: DbSession,
    authorization: Annotated[str | None, Header()] = None,
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise AuthenticationError("Missing or invalid authorization header")
    token = authorization.split(" ", 1)[1].strip()
    try:
        payload = decode_token(token)
        verify_token_type(payload, "access")
        user_id = int(payload["sub"])
    except (JWTError, ValueError, KeyError) as exc:
        raise AuthenticationError() from exc

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise AuthenticationError("User not found")
    return user


def get_optional_user(
    db: DbSession,
    authorization: Annotated[str | None, Header()] = None,
) -> User | None:
    if not authorization:
        return None
    try:
        return get_current_user(db, authorization)
    except AuthenticationError:
        return None


CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[User | None, Depends(get_optional_user)]

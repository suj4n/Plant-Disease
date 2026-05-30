from sqlalchemy.orm import Session

from app.core.exceptions import AppException, AuthenticationError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    get_password_hash,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import UserRegister


def register_user(db: Session, payload: UserRegister) -> User:
    if db.query(User).filter(User.email == payload.email).first():
        raise AppException("Email already registered", status_code=409)
    if db.query(User).filter(User.username == payload.username).first():
        raise AppException("Username already taken", status_code=409)

    user = User(
        email=payload.email.lower(),
        username=payload.username,
        password_hash=get_password_hash(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> User:
    user = db.query(User).filter(User.email == email.lower()).first()
    if not user or not verify_password(password, user.password_hash):
        raise AuthenticationError("Invalid email or password")
    return user


def issue_tokens(user: User) -> dict[str, str]:
    subject = str(user.id)
    return {
        "access_token": create_access_token(subject),
        "refresh_token": create_refresh_token(subject),
        "token_type": "bearer",
    }

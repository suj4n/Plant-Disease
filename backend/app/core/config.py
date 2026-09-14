from functools import lru_cache
from pathlib import Path

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = BACKEND_ROOT.parent

PLACEHOLDER_SECRET = "change-me-in-production-use-openssl-rand-hex-32"

DEV_CORS_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BACKEND_ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "PlantDoc API"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    database_url: str = f"sqlite:///{(BACKEND_ROOT / 'plantdoc.db').as_posix()}"

    secret_key: str = PLACEHOLDER_SECRET
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    #: Set to explicit origins in production. Credentials are only allowed when
    #: this is not the "*" wildcard (browsers reject wildcard + credentials).
    cors_origins: list[str] = DEV_CORS_ORIGINS

    model_path: Path = REPO_ROOT / "model" / "plant_best_model.keras"
    class_names_path: Path = REPO_ROOT / "Resources" / "class_names.json"
    upload_dir: Path = BACKEND_ROOT / "uploads"
    max_upload_size_mb: int = 10

    model_input_size: int = 224
    model_version: str = "mobilenetv2-20c-v1"

    @property
    def allow_credentials(self) -> bool:
        return "*" not in self.cors_origins

    @model_validator(mode="after")
    def _refuse_placeholder_secret_in_production(self) -> "Settings":
        if not self.debug and self.secret_key == PLACEHOLDER_SECRET:
            raise ValueError(
                "SECRET_KEY is still the placeholder value. Set a real secret "
                "(openssl rand -hex 32) before running with DEBUG=false."
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = BACKEND_ROOT.parent


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

    secret_key: str = "change-me-in-production-use-openssl-rand-hex-32"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    cors_origins: list[str] = ["*"]

    model_path: Path = REPO_ROOT / "model" / "plant_best_model.keras"
    class_names_path: Path = REPO_ROOT / "Resources" / "class_names.json"
    upload_dir: Path = BACKEND_ROOT / "uploads"
    max_upload_size_mb: int = 10

    model_input_size: int = 224


@lru_cache
def get_settings() -> Settings:
    return Settings()

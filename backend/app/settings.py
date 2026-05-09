from __future__ import annotations

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    _backend_dir: Path = Path(__file__).resolve().parents[2]

    model_config = SettingsConfigDict(
        # Resolve against backend/ so uvicorn can be run from repo root reliably.
        env_file=str(_backend_dir / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    model_path: str = "../model/best_model.keras"
    allow_origins: str = "*"
    default_top_k: int = 5

    # If true, load TensorFlow model on startup (fail fast).
    preload_model: bool = False

    # Upper bound for uploads (bytes). FastAPI/Starlette still reads into memory here,
    # but we can guard against accidentally huge files.
    max_upload_bytes: int = 10_000_000  # ~10MB

    # Logging level for uvicorn logger config.
    log_level: str = "INFO"


settings = Settings()


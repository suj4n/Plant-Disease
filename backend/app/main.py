import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes import api_router
from app.api.routes import detect as detect_routes
from app.api.routes import health as health_routes
from app.core.config import get_settings
from app.core.exceptions import AppException, InferenceError
from app.database.base import Base
from app.database.session import SessionLocal, engine
from app.services.disease_detection import get_detection_service
from app.services.seed_data import seed_plants_and_diseases

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    settings.upload_dir.mkdir(parents=True, exist_ok=True)

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_plants_and_diseases(db)
    finally:
        db.close()

    service = get_detection_service()
    try:
        service.load()
    except FileNotFoundError as exc:
        logger.error("Model load skipped: %s", exc)
    except Exception:
        logger.exception("Failed to load ML model")

    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health_routes.router)
    app.include_router(api_router, prefix=settings.api_v1_prefix)
    # Legacy Flutter endpoint (no /api/v1 prefix)
    app.include_router(detect_routes.legacy_router)

    register_exception_handlers(app)
    return app


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def app_exception_handler(_: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "message": exc.message},
        )

    @app.exception_handler(InferenceError)
    async def inference_exception_handler(_: Request, exc: InferenceError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "message": exc.message},
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        _: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        errors = exc.errors()
        message = errors[0].get("msg", "Validation error") if errors else "Validation error"
        return JSONResponse(
            status_code=422,
            content={"success": False, "message": message, "errors": errors},
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "message": exc.detail},
        )

    @app.exception_handler(SQLAlchemyError)
    async def db_exception_handler(_: Request, exc: SQLAlchemyError) -> JSONResponse:
        logger.exception("Database error: %s", exc)
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": "Database error"},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("Unhandled error: %s", exc)
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": "Internal server error"},
        )


app = create_app()

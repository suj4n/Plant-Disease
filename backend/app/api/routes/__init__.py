from fastapi import APIRouter

from app.api.routes import auth, detect, diseases, favorites, health, history, plants

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(detect.router)
api_router.include_router(history.router)
api_router.include_router(plants.router)
api_router.include_router(diseases.router)
api_router.include_router(favorites.router)

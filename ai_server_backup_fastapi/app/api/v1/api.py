from fastapi import APIRouter
from app.api.v1.endpoints import images, photos

api_router = APIRouter()

api_router.include_router(images.router, tags=["images"])
api_router.include_router(photos.router, prefix="/photos", tags=["photos"])

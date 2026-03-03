import os
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    PROJECT_NAME: str = "PetCam AI Server"
    API_V1_STR: str = "/api/v1"

    # Database
    DATABASE_URL: str = "postgresql://petuser:asd116511!@localhost/petdb"

    # Storage
    STORAGE_DIR: str = "storage"
    ORIGINALS_DIR: str = "storage/originals"
    RESULTS_DIR: str = "storage/results"

    # AI Model
    MODEL_PATH: str = "weights/RealESRGAN_x4.pth"
    MODEL_SCALE: int = 4

    class Config:
        case_sensitive = True


settings = Settings()

# Ensure storage directories exist
os.makedirs(settings.ORIGINALS_DIR, exist_ok=True)
os.makedirs(settings.RESULTS_DIR, exist_ok=True)

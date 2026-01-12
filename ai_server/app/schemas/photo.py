from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class PhotoBase(BaseModel):
    is_ai_processed: bool = False


class PhotoCreate(PhotoBase):
    id: str
    original_path: str
    upscaled_path: Optional[str] = None


class PhotoResponse(PhotoBase):
    id: str
    original_path: str
    upscaled_path: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

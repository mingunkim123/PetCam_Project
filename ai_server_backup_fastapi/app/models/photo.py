from sqlalchemy import Column, String, Boolean, DateTime
from app.core.database import Base
import datetime


class PhotoRecord(Base):
    __tablename__ = "photos"

    id = Column(String, primary_key=True, index=True)
    original_path = Column(String, nullable=False)
    upscaled_path = Column(String, nullable=True)
    is_ai_processed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

from sqlalchemy import Column, String, Boolean, DateTime, Float
from database import Base
import datetime


# DB 테이블 정의 (C++의 struct와 매칭)
class PhotoRecord(Base):
    __tablename__ = "photos"
    id = Column(String, primary_key=True, index=True)
    original_path = Column(String)
    upscaled_path = Column(String, nullable=True)
    is_ai_processed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    latitude = Column(Float, nullable=True)  # 📍 위도 추가
    longitude = Column(Float, nullable=True)  # 📍 경도 추가

from sqlalchemy import Column, String, DateTime, Float, Enum
from database import Base
import datetime
import enum


# 상태 Enum 정의
class ProcessingStatus(str, enum.Enum):
    UPLOADED = "UPLOADED"
    QUEUED = "QUEUED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


# DB 테이블 정의 (C++의 struct와 매칭)
class PhotoRecord(Base):
    __tablename__ = "photos"
    id = Column(String, primary_key=True, index=True)
    original_path = Column(String)
    upscaled_path = Column(String, nullable=True)

    # 상태 관리 (FSM)
    status = Column(Enum(ProcessingStatus), default=ProcessingStatus.UPLOADED)
    error_message = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    latitude = Column(Float, nullable=True)  # 📍 위도 추가
    longitude = Column(Float, nullable=True)  # 📍 경도 추가

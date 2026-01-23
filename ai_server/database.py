from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
import os

# DB 접속 규격 (Linker string)
# Docker 내부에서는 'db' 호스트네임을 사용, 로컬 개발 시에는 'localhost' 사용
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")

# AsyncPG 드라이버 사용을 위해 스키마 변경 (postgresql:// -> postgresql+asyncpg://)
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

engine = create_async_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)
Base = declarative_base()  # 테이블 설계를 위한 기본 클래스

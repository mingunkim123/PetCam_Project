"""
공통 의존성 (DB 세션, Rate Limiter 등)
"""

from sqlalchemy.ext.asyncio import AsyncSession
from slowapi import Limiter
from slowapi.util import get_remote_address

from database import SessionLocal

# Rate Limiter (전역)
limiter = Limiter(key_func=get_remote_address)


async def get_db():
    """비동기 DB 세션 생성"""
    async with SessionLocal() as db:
        try:
            yield db
        finally:
            await db.close()

"""
PetCam AI Server - 메인 진입점

라우터:
- /health: 헬스체크
- /register, /token: 인증
- /upscale, /bestcut, /photos: 사진 처리
"""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from database import Base, engine

# 라우터 import
from app.api.auth import router as auth_router
from app.api.health import router as health_router
from app.api.photos import router as photos_router
from app.core.deps import limiter

# FastAPI 앱 생성
app = FastAPI(title="PetCam AI Server", version="1.0.0")

# Rate Limiter 설정
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인으로 제한 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 라우터 등록
app.include_router(health_router)
app.include_router(auth_router)
app.include_router(photos_router)


# DB 테이블 생성
@app.on_event("startup")
async def startup_event():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


if __name__ == "__main__":
    import uvicorn
    from dotenv import load_dotenv

    load_dotenv()

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))

    uvicorn.run(app, host=host, port=port)

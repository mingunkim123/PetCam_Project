"""
PetCam AI Server - 메인 진입점

라우터:
- /health: 헬스체크
- /register, /token: 인증
- /upscale, /bestcut, /photos: 사진 처리
"""

import os
import logging

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

# 로깅 설정
log_level = os.getenv("LOG_LEVEL", "info").upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="PetCam AI Server",
    version="1.0.0",
    description="반려동물 모니터링을 위한 AI 이미지 처리 서버",
)

# Rate Limiter 설정
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ============================================================
# CORS 설정 (Cross-Origin Resource Sharing)
# ============================================================
# CORS란?
#   웹 브라우저의 보안 정책으로, 다른 도메인에서 오는 요청을 차단합니다.
#   예: petcam.com 웹사이트에서 api.petcam.com으로 요청할 때 필요
#
# ALLOWED_ORIGINS 환경변수:
#   - "*" : 모든 도메인 허용 (개발용, 보안 취약)
#   - "https://petcam.com,https://app.petcam.com" : 특정 도메인만 허용 (프로덕션 권장)
# ============================================================

def get_cors_origins() -> list:
    """환경변수에서 CORS 허용 도메인 목록을 가져옵니다."""
    allowed_origins = os.getenv("ALLOWED_ORIGINS", "*")
    
    if allowed_origins == "*":
        logger.warning("⚠️  CORS: 모든 도메인 허용 중 (개발 모드)")
        return ["*"]
    
    # 쉼표로 구분된 도메인 목록을 리스트로 변환
    origins = [origin.strip() for origin in allowed_origins.split(",") if origin.strip()]
    logger.info(f"✅ CORS: 허용된 도메인 - {origins}")
    return origins


cors_origins = get_cors_origins()

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
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

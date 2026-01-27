"""
헬스체크 API 라우터
"""

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    """서버 상태 확인용 헬스체크 엔드포인트"""
    return {"status": "ok", "version": "1.0.0"}

"""
=============================================================================
PetCam AI Server - 헬스체크 API 테스트
=============================================================================

테스트 대상:
    GET /health - 서버가 살아있는지 확인하는 API

왜 필요한가요?
    서버가 정상적으로 동작하는지 확인하는 가장 기본적인 테스트입니다.
    마치 심장이 뛰는지 확인하는 것과 같습니다.
    
실행 방법:
    pytest tests/test_health.py -v
=============================================================================
"""

import pytest
from httpx import AsyncClient


# =============================================================================
# 테스트 1: 헬스체크 기본 동작
# =============================================================================

@pytest.mark.asyncio  # 이 테스트는 비동기로 실행됩니다
async def test_health_check_returns_ok(client: AsyncClient):
    """
    헬스체크 API가 정상 응답을 반환하는지 확인합니다.
    
    테스트 시나리오:
        1. GET /health 요청을 보냄
        2. 상태 코드가 200(성공)인지 확인
        3. 응답에 "status": "ok"가 있는지 확인
    
    기대 결과:
        {
            "status": "ok",
            "version": "1.0.0"
        }
    """
    # =====================
    # 1단계: API 요청 보내기
    # =====================
    response = await client.get("/health")
    
    # =====================
    # 2단계: 상태 코드 확인
    # =====================
    # 200 = 요청 성공
    # 만약 404면 "페이지를 찾을 수 없음"
    # 만약 500이면 "서버 오류"
    assert response.status_code == 200, \
        f"예상: 200, 실제: {response.status_code}"
    
    # =====================
    # 3단계: 응답 내용 확인
    # =====================
    data = response.json()  # JSON 응답을 파이썬 딕셔너리로 변환
    
    # "status" 필드가 있는지 확인
    assert "status" in data, \
        "응답에 'status' 필드가 없습니다"
    
    # "status"가 "ok"인지 확인
    assert data["status"] == "ok", \
        f"예상: 'ok', 실제: '{data['status']}'"


# =============================================================================
# 테스트 2: 헬스체크에 버전 정보가 포함되어 있는지
# =============================================================================

@pytest.mark.asyncio
async def test_health_check_includes_version(client: AsyncClient):
    """
    헬스체크 응답에 버전 정보가 포함되어 있는지 확인합니다.
    
    왜 버전이 필요한가요?
        - 현재 어떤 버전이 배포되어 있는지 확인 가능
        - 문제 발생 시 어떤 버전에서 문제가 생겼는지 파악 가능
    """
    # API 요청
    response = await client.get("/health")
    data = response.json()
    
    # "version" 필드 확인
    assert "version" in data, \
        "응답에 'version' 필드가 없습니다"
    
    # 버전이 비어있지 않은지 확인
    assert len(data["version"]) > 0, \
        "버전 정보가 비어있습니다"


# =============================================================================
# 테스트 3: 헬스체크 응답 시간 확인
# =============================================================================

@pytest.mark.asyncio
async def test_health_check_response_time(client: AsyncClient):
    """
    헬스체크가 빠르게 응답하는지 확인합니다.
    
    왜 중요한가요?
        헬스체크는 서버 상태를 자주 확인하는 용도입니다.
        너무 느리면 모니터링에 문제가 생깁니다.
        
    기준:
        - 1초 이내에 응답해야 함 (실제로는 훨씬 빠름)
    """
    import time
    
    # 시작 시간 기록
    start_time = time.time()
    
    # API 요청
    response = await client.get("/health")
    
    # 종료 시간 기록
    end_time = time.time()
    
    # 응답 시간 계산 (초 단위)
    response_time = end_time - start_time
    
    # 1초 이내인지 확인
    assert response_time < 1.0, \
        f"헬스체크가 너무 느립니다: {response_time:.2f}초"
    
    # 요청도 성공했는지 확인
    assert response.status_code == 200

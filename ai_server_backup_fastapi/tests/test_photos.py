"""
=============================================================================
PetCam AI Server - 사진 API 테스트
=============================================================================

테스트 대상:
    - GET /photos - 사진 목록 조회
    - POST /upscale - 사진 업로드 및 업스케일
    - GET /photos/{id} - 특정 사진 조회
    - DELETE /photos/{id} - 사진 삭제

이 테스트들이 확인하는 것:
    1. 사진 목록을 정상적으로 가져오는지
    2. 페이지네이션(skip, limit)이 동작하는지
    3. 인증 없이 접근하면 거부되는지
    
주의사항:
    - 실제 업스케일(AI 처리)은 시간이 오래 걸리므로 모킹(가짜)으로 테스트
    - 파일 업로드 테스트는 실제 이미지 파일이 필요
    
실행 방법:
    pytest tests/test_photos.py -v
=============================================================================
"""

import pytest
from httpx import AsyncClient
from unittest.mock import patch, AsyncMock


# =============================================================================
# 사진 목록 조회 테스트
# =============================================================================

class TestGetPhotos:
    """
    사진 목록 조회 API 테스트 모음
    
    GET /photos
    """

    # =========================================================================
    # 테스트 1: 빈 목록 조회
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_empty(self, authenticated_client: AsyncClient):
        """
        사진이 없을 때 빈 목록을 반환하는지 확인합니다.
        
        시나리오:
            1. 아직 사진을 업로드하지 않은 상태
            2. /photos 요청
            3. 빈 리스트 [] 응답 확인
        """
        # API 요청 (이미 인증된 클라이언트 사용)
        response = await authenticated_client.get("/photos")
        
        # 상태 코드 확인
        assert response.status_code == 200, \
            f"사진 목록 조회 실패: {response.status_code}"
        
        # 응답 데이터 확인
        data = response.json()
        
        # 리스트 형태인지 확인
        assert isinstance(data, list), \
            f"응답이 리스트가 아닙니다: {type(data)}"
        
        # 비어있는지 확인 (아직 업로드한 사진 없음)
        assert len(data) == 0, \
            f"빈 목록이어야 하는데 {len(data)}개가 있습니다"

    # =========================================================================
    # 테스트 2: 인증 없이 접근 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_without_auth(self, client: AsyncClient):
        """
        인증 없이 사진 목록을 요청하면 거부되는지 확인합니다.
        
        왜 중요한가요?
            다른 사람의 사진을 아무나 볼 수 있으면 안 됩니다!
        """
        # 인증 없이 요청 (일반 client 사용)
        response = await client.get("/photos")
        
        # 401 = 인증 필요
        assert response.status_code == 401, \
            "인증 없이 사진 목록에 접근이 허용되었습니다"

    # =========================================================================
    # 테스트 3: 페이지네이션 - skip 파라미터
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_with_skip(self, authenticated_client: AsyncClient):
        """
        skip 파라미터가 정상 동작하는지 확인합니다.
        
        skip이 뭔가요?
            "처음 N개는 건너뛰어"라는 의미입니다.
            예: skip=10이면 11번째 사진부터 보여줌
            
            인스타그램 스크롤처럼, 아래로 내리면 다음 사진들을 가져올 때 사용
        """
        # skip=0 요청 (처음부터)
        response = await authenticated_client.get("/photos?skip=0")
        
        assert response.status_code == 200
        
        # skip=10 요청 (11번째부터)
        response = await authenticated_client.get("/photos?skip=10")
        
        assert response.status_code == 200

    # =========================================================================
    # 테스트 4: 페이지네이션 - limit 파라미터
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_with_limit(self, authenticated_client: AsyncClient):
        """
        limit 파라미터가 정상 동작하는지 확인합니다.
        
        limit이 뭔가요?
            "최대 N개만 가져와"라는 의미입니다.
            예: limit=20이면 최대 20개만 응답
            
            한 번에 너무 많은 데이터를 가져오면 느려지니까 제한합니다.
        """
        # limit=10 요청 (최대 10개)
        response = await authenticated_client.get("/photos?limit=10")
        
        assert response.status_code == 200
        
        data = response.json()
        
        # 10개 이하인지 확인
        assert len(data) <= 10, \
            f"limit=10인데 {len(data)}개가 반환되었습니다"

    # =========================================================================
    # 테스트 5: 잘못된 skip 값 (음수)
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_invalid_skip(self, authenticated_client: AsyncClient):
        """
        음수 skip 값이 거부되는지 확인합니다.
        
        왜 확인하나요?
            skip=-1 같은 이상한 값이 들어오면 오류가 날 수 있습니다.
            미리 막아두는 것이 안전합니다.
        """
        # 음수 skip 요청
        response = await authenticated_client.get("/photos?skip=-1")
        
        # 422 = 데이터 검증 실패
        assert response.status_code == 422, \
            "음수 skip 값이 허용되었습니다"

    # =========================================================================
    # 테스트 6: limit 최대값 초과
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photos_limit_exceeded(self, authenticated_client: AsyncClient):
        """
        limit이 최대값(1000)을 초과하면 거부되는지 확인합니다.
        
        왜 제한하나요?
            limit=999999 같은 값이 들어오면 서버가 힘들어집니다.
            메모리 부족, 응답 지연 등의 문제가 생길 수 있습니다.
        """
        # limit=9999 요청 (최대값 1000 초과)
        response = await authenticated_client.get("/photos?limit=9999")
        
        # 422 = 데이터 검증 실패
        assert response.status_code == 422, \
            "limit 최대값 초과가 허용되었습니다"


# =============================================================================
# 사진 업로드 테스트
# =============================================================================

class TestUploadPhoto:
    """
    사진 업로드 API 테스트 모음
    
    POST /upscale
    """

    # =========================================================================
    # 테스트 1: 인증 없이 업로드 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_upload_without_auth(self, client: AsyncClient):
        """
        인증 없이 사진을 업로드하면 거부되는지 확인합니다.
        """
        # 가짜 파일 데이터
        files = {
            "file": ("test.jpg", b"fake image data", "image/jpeg")
            #        파일명       파일내용(바이트)     파일타입
        }
        
        response = await client.post("/upscale", files=files)
        
        # 401 = 인증 필요
        assert response.status_code == 401, \
            "인증 없이 사진 업로드가 허용되었습니다"

    # =========================================================================
    # 테스트 2: 파일 없이 업로드 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_upload_no_file(self, authenticated_client: AsyncClient):
        """
        파일 없이 업로드 요청하면 거부되는지 확인합니다.
        """
        # 파일 없이 요청
        response = await authenticated_client.post("/upscale")
        
        # 422 = 데이터 검증 실패 (필수 파일 누락)
        assert response.status_code == 422, \
            "파일 없는 업로드가 허용되었습니다"


# =============================================================================
# 사진 삭제 테스트
# =============================================================================

class TestDeletePhoto:
    """
    사진 삭제 API 테스트 모음
    
    DELETE /photos/{photo_id}
    """

    # =========================================================================
    # 테스트 1: 존재하지 않는 사진 삭제 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_delete_nonexistent_photo(self, authenticated_client: AsyncClient):
        """
        존재하지 않는 사진을 삭제하면 404 에러가 발생하는지 확인합니다.
        """
        # 가짜 사진 ID로 삭제 요청
        fake_photo_id = "00000000-0000-0000-0000-000000000000"
        
        response = await authenticated_client.delete(f"/photos/{fake_photo_id}")
        
        # 404 = 찾을 수 없음
        assert response.status_code == 404, \
            f"존재하지 않는 사진 삭제 시 {response.status_code} 반환"

    # =========================================================================
    # 테스트 2: 인증 없이 삭제 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_delete_without_auth(self, client: AsyncClient):
        """
        인증 없이 사진을 삭제하면 거부되는지 확인합니다.
        """
        fake_photo_id = "00000000-0000-0000-0000-000000000000"
        
        response = await client.delete(f"/photos/{fake_photo_id}")
        
        # 401 = 인증 필요
        assert response.status_code == 401, \
            "인증 없이 사진 삭제가 허용되었습니다"


# =============================================================================
# 특정 사진 조회 테스트
# =============================================================================

class TestGetPhotoById:
    """
    특정 사진 조회 API 테스트 모음
    
    GET /photos/{photo_id}
    """

    # =========================================================================
    # 테스트 1: 존재하지 않는 사진 조회
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_nonexistent_photo(self, authenticated_client: AsyncClient):
        """
        존재하지 않는 사진을 조회하면 404 에러가 발생하는지 확인합니다.
        """
        fake_photo_id = "00000000-0000-0000-0000-000000000000"
        
        response = await authenticated_client.get(f"/photos/{fake_photo_id}")
        
        # 404 = 찾을 수 없음
        assert response.status_code == 404, \
            f"존재하지 않는 사진 조회 시 {response.status_code} 반환"

    # =========================================================================
    # 테스트 2: 인증 없이 조회 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_get_photo_without_auth(self, client: AsyncClient):
        """
        인증 없이 사진을 조회하면 거부되는지 확인합니다.
        """
        fake_photo_id = "00000000-0000-0000-0000-000000000000"
        
        response = await client.get(f"/photos/{fake_photo_id}")
        
        # 401 = 인증 필요
        assert response.status_code == 401, \
            "인증 없이 사진 조회가 허용되었습니다"

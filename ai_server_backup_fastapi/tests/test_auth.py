"""
=============================================================================
PetCam AI Server - 인증 API 테스트
=============================================================================

테스트 대상:
    - POST /register - 회원가입
    - POST /token - 로그인 (토큰 발급)

이 테스트들이 확인하는 것:
    1. 회원가입이 정상적으로 되는지
    2. 중복 아이디로 가입하면 거부되는지
    3. 너무 짧은 비밀번호는 거부되는지
    4. 로그인이 정상적으로 되는지
    5. 잘못된 비밀번호로 로그인하면 거부되는지
    
실행 방법:
    pytest tests/test_auth.py -v
=============================================================================
"""

import pytest
from httpx import AsyncClient


# =============================================================================
# 회원가입 테스트
# =============================================================================

class TestRegister:
    """
    회원가입 API 테스트 모음
    
    비유:
        새로운 회원이 가입할 때 발생할 수 있는 
        모든 상황을 테스트합니다.
    """

    # =========================================================================
    # 테스트 1: 정상적인 회원가입
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_register_success(self, client: AsyncClient):
        """
        정상적인 회원가입이 성공하는지 확인합니다.
        
        시나리오:
            1. 새로운 아이디와 비밀번호로 회원가입 요청
            2. 성공 응답(200) 확인
            3. 응답에 사용자 정보가 있는지 확인
        """
        # =====================
        # 1단계: 회원가입 요청
        # =====================
        # 새로운 사용자 정보
        new_user = {
            "username": "newuser",      # 아이디 (3자 이상)
            "password": "securepass123"  # 비밀번호 (6자 이상)
        }
        
        # POST 요청 보내기
        response = await client.post(
            "/register",           # 요청할 주소
            json=new_user          # 보낼 데이터 (JSON 형식)
        )
        
        # =====================
        # 2단계: 응답 확인
        # =====================
        # 200 = 성공
        assert response.status_code == 200, \
            f"회원가입 실패: {response.status_code} - {response.text}"
        
        # =====================
        # 3단계: 응답 데이터 확인
        # =====================
        data = response.json()
        
        # 아이디가 응답에 있는지 확인
        assert data["username"] == "newuser", \
            "응답의 username이 요청과 다릅니다"
        
        # 사용자 ID가 생성되었는지 확인
        assert "id" in data, \
            "응답에 사용자 ID가 없습니다"
        
        # 활성 상태인지 확인
        assert data["is_active"] == True, \
            "새 사용자가 비활성 상태입니다"

    # =========================================================================
    # 테스트 2: 중복 아이디로 가입 시도
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_register_duplicate_username(
        self, 
        client: AsyncClient, 
        test_user  # conftest.py에서 만든 기존 사용자
    ):
        """
        이미 존재하는 아이디로 가입하면 거부되는지 확인합니다.
        
        시나리오:
            1. 이미 존재하는 "testuser"로 가입 시도
            2. 400 에러(잘못된 요청) 응답 확인
        
        왜 중요한가요?
            같은 아이디가 두 개 있으면 누가 진짜 주인인지 알 수 없습니다.
        """
        # 이미 존재하는 아이디로 가입 시도
        duplicate_user = {
            "username": "testuser",  # 이미 있는 아이디!
            "password": "anotherpass123"
        }
        
        response = await client.post("/register", json=duplicate_user)
        
        # 400 = 잘못된 요청 (클라이언트 잘못)
        assert response.status_code == 400, \
            "중복 아이디가 허용되었습니다 (보안 문제!)"
        
        # 에러 메시지 확인
        data = response.json()
        assert "already registered" in data["detail"].lower(), \
            "중복 아이디 에러 메시지가 명확하지 않습니다"

    # =========================================================================
    # 테스트 3: 너무 짧은 아이디
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_register_username_too_short(self, client: AsyncClient):
        """
        아이디가 3자 미만이면 거부되는지 확인합니다.
        
        왜 제한하나요?
            너무 짧은 아이디는 추측하기 쉽고 관리가 어렵습니다.
        """
        short_username = {
            "username": "ab",  # 2자 - 너무 짧음!
            "password": "validpassword123"
        }
        
        response = await client.post("/register", json=short_username)
        
        # 422 = 데이터 검증 실패
        assert response.status_code == 422, \
            "짧은 아이디가 허용되었습니다"

    # =========================================================================
    # 테스트 4: 너무 짧은 비밀번호
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_register_password_too_short(self, client: AsyncClient):
        """
        비밀번호가 6자 미만이면 거부되는지 확인합니다.
        
        왜 제한하나요?
            짧은 비밀번호는 해킹당하기 쉽습니다.
            "123"같은 비밀번호는 몇 초만에 뚫립니다.
        """
        short_password = {
            "username": "validuser",
            "password": "12345"  # 5자 - 너무 짧음!
        }
        
        response = await client.post("/register", json=short_password)
        
        # 422 = 데이터 검증 실패
        assert response.status_code == 422, \
            "짧은 비밀번호가 허용되었습니다 (보안 문제!)"


# =============================================================================
# 로그인 테스트
# =============================================================================

class TestLogin:
    """
    로그인 API 테스트 모음
    
    비유:
        회원이 로그인할 때 발생할 수 있는
        모든 상황을 테스트합니다.
    """

    # =========================================================================
    # 테스트 1: 정상적인 로그인
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_login_success(
        self, 
        client: AsyncClient, 
        test_user  # conftest.py에서 만든 테스트 사용자
    ):
        """
        올바른 아이디와 비밀번호로 로그인이 성공하는지 확인합니다.
        
        시나리오:
            1. 올바른 아이디/비밀번호로 로그인 요청
            2. 성공 응답(200) 확인
            3. JWT 토큰이 발급되었는지 확인
        """
        # =====================
        # 1단계: 로그인 요청
        # =====================
        # OAuth2 표준 형식 (form 데이터)
        login_data = {
            "username": "testuser",       # 테스트 사용자 아이디
            "password": "testpassword123"  # 테스트 사용자 비밀번호
        }
        
        # POST 요청 (form 형식)
        response = await client.post(
            "/token",
            data=login_data  # json이 아니라 data! (OAuth2 표준)
        )
        
        # =====================
        # 2단계: 응답 확인
        # =====================
        assert response.status_code == 200, \
            f"로그인 실패: {response.status_code} - {response.text}"
        
        # =====================
        # 3단계: 토큰 확인
        # =====================
        data = response.json()
        
        # access_token이 있는지 확인
        assert "access_token" in data, \
            "응답에 access_token이 없습니다"
        
        # 토큰이 비어있지 않은지 확인
        assert len(data["access_token"]) > 0, \
            "access_token이 비어있습니다"
        
        # token_type이 "bearer"인지 확인
        assert data["token_type"] == "bearer", \
            f"token_type이 'bearer'가 아닙니다: {data['token_type']}"

    # =========================================================================
    # 테스트 2: 잘못된 비밀번호
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_login_wrong_password(
        self, 
        client: AsyncClient, 
        test_user
    ):
        """
        잘못된 비밀번호로 로그인하면 거부되는지 확인합니다.
        
        왜 중요한가요?
            비밀번호가 틀려도 로그인되면 보안 사고입니다!
        """
        wrong_login = {
            "username": "testuser",
            "password": "wrongpassword"  # 틀린 비밀번호!
        }
        
        response = await client.post("/token", data=wrong_login)
        
        # 401 = 인증 실패
        assert response.status_code == 401, \
            "잘못된 비밀번호로 로그인이 허용되었습니다 (심각한 보안 문제!)"

    # =========================================================================
    # 테스트 3: 존재하지 않는 사용자
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, client: AsyncClient):
        """
        존재하지 않는 아이디로 로그인하면 거부되는지 확인합니다.
        """
        nonexistent = {
            "username": "nobody",  # 없는 아이디
            "password": "anypassword"
        }
        
        response = await client.post("/token", data=nonexistent)
        
        # 401 = 인증 실패
        assert response.status_code == 401, \
            "존재하지 않는 사용자로 로그인이 허용되었습니다"

    # =========================================================================
    # 테스트 4: 토큰으로 인증된 요청
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_authenticated_request(
        self, 
        client: AsyncClient, 
        auth_token: str  # conftest.py에서 만든 토큰
    ):
        """
        발급받은 토큰으로 인증이 필요한 API에 접근할 수 있는지 확인합니다.
        
        시나리오:
            1. 토큰을 헤더에 넣어서 /photos 요청
            2. 인증 성공(200) 확인
        """
        # 인증 헤더 설정
        headers = {
            "Authorization": f"Bearer {auth_token}"
            #              ↑ "Bearer " 뒤에 토큰을 붙이는 것이 표준
        }
        
        # 인증이 필요한 API 호출
        response = await client.get("/photos", headers=headers)
        
        # 200 = 성공 (인증 통과)
        assert response.status_code == 200, \
            f"토큰 인증 실패: {response.status_code}"

    # =========================================================================
    # 테스트 5: 토큰 없이 인증 필요 API 접근
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_unauthenticated_request(self, client: AsyncClient):
        """
        토큰 없이 인증이 필요한 API에 접근하면 거부되는지 확인합니다.
        
        왜 중요한가요?
            로그인 안 한 사람이 다른 사람의 사진을 볼 수 있으면 안 됩니다!
        """
        # 토큰 없이 요청
        response = await client.get("/photos")
        
        # 401 = 인증 필요
        assert response.status_code == 401, \
            "토큰 없이 인증 필요 API에 접근이 허용되었습니다"

    # =========================================================================
    # 테스트 6: 잘못된 토큰
    # =========================================================================
    
    @pytest.mark.asyncio
    async def test_invalid_token(self, client: AsyncClient):
        """
        가짜/잘못된 토큰으로 접근하면 거부되는지 확인합니다.
        
        왜 중요한가요?
            해커가 만든 가짜 토큰이 통과되면 큰일납니다!
        """
        # 가짜 토큰
        headers = {
            "Authorization": "Bearer fake-token-12345"
        }
        
        response = await client.get("/photos", headers=headers)
        
        # 401 = 인증 실패
        assert response.status_code == 401, \
            "가짜 토큰이 인증을 통과했습니다 (심각한 보안 문제!)"

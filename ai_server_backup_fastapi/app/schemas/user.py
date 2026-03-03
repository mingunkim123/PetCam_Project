"""
=============================================================================
User 관련 Pydantic 스키마 (요청/응답 검증)
=============================================================================

스키마가 뭔가요?
    API로 들어오고 나가는 데이터의 '형식'을 정의합니다.
    마치 택배 상자 규격처럼, 어떤 모양의 데이터가 오가야 하는지 정합니다.
    
    장점:
    - 잘못된 데이터가 들어오면 자동으로 거부
    - API 문서 자동 생성
    - 개발자가 어떤 데이터를 보내야 하는지 명확히 알 수 있음
=============================================================================
"""

from typing import Optional
from pydantic import BaseModel, Field


# =============================================================================
# 회원가입 관련 스키마
# =============================================================================

class UserCreate(BaseModel):
    """
    회원가입 요청 스키마
    
    필드:
        username: 아이디 (3~50자)
        password: 비밀번호 (6~100자)
    """
    username: str = Field(
        ...,                    # ... = 필수 입력
        min_length=3,           # 최소 3자
        max_length=50,          # 최대 50자
        description="사용자 아이디"
    )
    password: str = Field(
        ...,
        min_length=6,           # 최소 6자 (보안)
        max_length=100,
        description="비밀번호"
    )


class UserResponse(BaseModel):
    """
    사용자 정보 응답 스키마
    
    회원가입 성공, 사용자 조회 등에서 사용
    """
    id: str
    username: str
    is_active: bool
    
    # 소셜 로그인 정보 (선택)
    provider: Optional[str] = None  # "kakao", "google" 등
    
    class Config:
        from_attributes = True  # ORM 모델에서 자동 변환 허용


# =============================================================================
# 토큰 관련 스키마
# =============================================================================

class Token(BaseModel):
    """
    기본 JWT 토큰 응답 스키마
    
    로그인 성공 시 반환 (Access Token만)
    """
    access_token: str
    token_type: str = "bearer"


class TokenWithRefresh(BaseModel):
    """
    Refresh Token 포함 토큰 응답 스키마
    
    로그인 성공 시 반환 (Access Token + Refresh Token)
    
    왜 2개를 주나요?
        - access_token: API 요청에 사용 (유효기간 짧음, 30분)
        - refresh_token: access_token 갱신에 사용 (유효기간 김, 7일)
    """
    access_token: str           # API 요청용 토큰
    refresh_token: str          # 갱신용 토큰
    token_type: str = "bearer"
    expires_in: int = 1800      # Access Token 만료 시간 (초) - 기본 30분


class TokenRefreshRequest(BaseModel):
    """
    토큰 갱신 요청 스키마
    
    사용 시나리오:
        1. Access Token이 만료됨
        2. 클라이언트가 refresh_token을 서버로 보냄
        3. 서버가 새 Access Token을 발급
    """
    refresh_token: str = Field(
        ...,
        description="갱신용 Refresh Token"
    )


class TokenData(BaseModel):
    """
    토큰 페이로드 스키마 (내부 사용)
    
    JWT 토큰 안에 들어있는 데이터
    """
    username: Optional[str] = None


# =============================================================================
# 카카오 로그인 관련 스키마
# =============================================================================

class KakaoLoginRequest(BaseModel):
    """
    카카오 로그인 요청 스키마
    
    사용 시나리오:
        1. 앱에서 카카오 로그인 → 카카오 access_token 받음
        2. 카카오 access_token을 우리 서버로 전송
        3. 우리 서버가 카카오에서 사용자 정보 조회
        4. 우리 서버의 JWT 토큰 발급
    """
    kakao_access_token: str = Field(
        ...,
        description="카카오에서 받은 Access Token"
    )


class KakaoUserInfo(BaseModel):
    """
    카카오 사용자 정보 스키마
    
    카카오 API에서 받아오는 사용자 정보
    """
    id: int                         # 카카오 사용자 고유 ID
    nickname: Optional[str] = None  # 닉네임
    email: Optional[str] = None     # 이메일 (동의한 경우만)
    profile_image: Optional[str] = None  # 프로필 이미지 URL

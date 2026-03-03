"""
=============================================================================
소셜 로그인 API 라우터 (카카오)
=============================================================================

카카오 로그인 흐름:

    [앱(Flutter)]                    [우리 서버]                    [카카오]
         │                               │                            │
         │  1. 카카오 로그인 버튼 클릭    │                            │
         │─────────────────────────────────────────────────────────────>│
         │                               │                            │
         │  2. 카카오 로그인 화면         │                            │
         │<─────────────────────────────────────────────────────────────│
         │                               │                            │
         │  3. 로그인 성공 → 카카오 토큰  │                            │
         │<─────────────────────────────────────────────────────────────│
         │                               │                            │
         │  4. 카카오 토큰을 우리 서버로  │                            │
         │──────────────────────────────>│                            │
         │                               │                            │
         │                               │  5. 카카오 API로 사용자 정보 조회
         │                               │────────────────────────────>│
         │                               │                            │
         │                               │  6. 사용자 정보 응답        │
         │                               │<────────────────────────────│
         │                               │                            │
         │                               │  7. 사용자 생성 또는 조회   │
         │                               │  8. JWT 토큰 발급          │
         │                               │                            │
         │  9. 우리 서버의 JWT 토큰      │                            │
         │<──────────────────────────────│                            │

=============================================================================
"""

import os
import httpx
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.auth import (
    create_access_token,
    create_refresh_token,
    get_password_hash,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)
from app.models.user import User
from app.schemas.user import (
    KakaoLoginRequest,
    KakaoUserInfo,
    TokenWithRefresh,
)
from app.core.deps import get_db, limiter


router = APIRouter(prefix="/oauth", tags=["oauth"])


# =============================================================================
# 카카오 API 설정
# =============================================================================

# 카카오 사용자 정보 조회 API URL
KAKAO_USER_INFO_URL = "https://kapi.kakao.com/v2/user/me"


# =============================================================================
# 카카오 API 호출 함수
# =============================================================================

async def get_kakao_user_info(kakao_access_token: str) -> Optional[KakaoUserInfo]:
    """
    카카오 API를 호출하여 사용자 정보를 가져옵니다.
    
    동작 과정:
        1. 카카오 Access Token을 헤더에 넣어서 요청
        2. 카카오 서버가 사용자 정보 응답
        3. 응답을 KakaoUserInfo 객체로 변환
    
    Args:
        kakao_access_token: 카카오에서 발급받은 Access Token
    
    Returns:
        성공 시 KakaoUserInfo 객체, 실패 시 None
    """
    # HTTP 클라이언트 생성 (비동기)
    async with httpx.AsyncClient() as client:
        try:
            # 카카오 API 호출
            response = await client.get(
                KAKAO_USER_INFO_URL,
                headers={
                    "Authorization": f"Bearer {kakao_access_token}",
                    "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
                }
            )
            
            # 응답 확인
            if response.status_code != 200:
                # 카카오 토큰이 유효하지 않음
                return None
            
            # JSON 파싱
            data = response.json()
            
            # 사용자 정보 추출
            kakao_id = data.get("id")  # 카카오 고유 ID (숫자)
            
            # 카카오 계정 정보 (동의한 항목만 포함됨)
            kakao_account = data.get("kakao_account", {})
            profile = kakao_account.get("profile", {})
            
            return KakaoUserInfo(
                id=kakao_id,
                nickname=profile.get("nickname"),
                email=kakao_account.get("email"),  # 이메일 동의한 경우만
                profile_image=profile.get("profile_image_url"),
            )
            
        except Exception as e:
            # 네트워크 오류 등
            print(f"카카오 API 호출 실패: {e}")
            return None


# =============================================================================
# 카카오 로그인 API
# =============================================================================

@router.post("/kakao", response_model=TokenWithRefresh)
@limiter.limit("10/minute")
async def kakao_login(
    request: Request,
    login_request: KakaoLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    카카오 로그인
    
    사용 방법:
        1. 앱에서 카카오 SDK로 로그인
        2. 카카오에서 받은 access_token을 이 API로 전송
        3. 우리 서버의 JWT 토큰 받음
    
    요청 본문:
        - kakao_access_token: 카카오에서 받은 Access Token
    
    응답:
        - access_token: 우리 서버의 Access Token
        - refresh_token: 우리 서버의 Refresh Token
        - token_type: "bearer"
        - expires_in: 만료 시간 (초)
    
    에러:
        - 401: 카카오 토큰이 유효하지 않음
        - 500: 서버 오류
    
    특이사항:
        - 처음 로그인하는 사용자는 자동으로 계정 생성
        - 아이디는 "kakao_카카오ID" 형식 (예: kakao_123456789)
        - 비밀번호는 랜덤 생성 (소셜 로그인이라 사용 안 함)
    """
    # =========================================================================
    # 1단계: 카카오 API로 사용자 정보 조회
    # =========================================================================
    kakao_user = await get_kakao_user_info(login_request.kakao_access_token)
    
    if not kakao_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Kakao access token",
        )
    
    # =========================================================================
    # 2단계: 우리 DB에서 사용자 조회 또는 생성
    # =========================================================================
    
    # 카카오 ID를 기반으로 고유한 username 생성
    # 예: 카카오 ID가 123456789면 → "kakao_123456789"
    kakao_username = f"kakao_{kakao_user.id}"
    
    # DB에서 사용자 조회
    result = await db.execute(
        select(User).filter(User.username == kakao_username)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        # =====================================================================
        # 신규 사용자: 자동 회원가입
        # =====================================================================
        # 소셜 로그인 사용자는 비밀번호를 직접 사용하지 않으므로
        # 랜덤한 비밀번호를 생성해서 저장합니다.
        import secrets
        random_password = secrets.token_urlsafe(32)
        hashed_password = get_password_hash(random_password)
        
        user = User(
            username=kakao_username,
            hashed_password=hashed_password,
            is_active=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        print(f"✅ 카카오 신규 사용자 생성: {kakao_username}")
    else:
        print(f"✅ 카카오 기존 사용자 로그인: {kakao_username}")
    
    # =========================================================================
    # 3단계: 우리 서버의 JWT 토큰 발급
    # =========================================================================
    
    # Access Token 생성
    access_token = create_access_token(data={"sub": user.username})
    
    # Refresh Token 생성 및 DB 저장
    refresh_token = await create_refresh_token(db, str(user.id))
    
    return TokenWithRefresh(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


# =============================================================================
# 카카오 사용자 정보 조회 API (디버깅용)
# =============================================================================

@router.get("/kakao/userinfo")
@limiter.limit("10/minute")
async def get_kakao_user(
    request: Request,
    kakao_access_token: str,
):
    """
    카카오 사용자 정보 조회 (디버깅/테스트용)
    
    카카오 토큰이 유효한지 확인하고 싶을 때 사용합니다.
    
    쿼리 파라미터:
        - kakao_access_token: 카카오에서 받은 Access Token
    
    응답:
        - id: 카카오 사용자 ID
        - nickname: 닉네임
        - email: 이메일 (동의한 경우)
        - profile_image: 프로필 이미지 URL
    """
    kakao_user = await get_kakao_user_info(kakao_access_token)
    
    if not kakao_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Kakao access token",
        )
    
    return kakao_user
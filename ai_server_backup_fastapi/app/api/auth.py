"""
=============================================================================
인증 관련 API 라우터
=============================================================================

엔드포인트 목록:
    POST /register       - 회원가입
    POST /token          - 로그인 (Access Token + Refresh Token 발급)
    POST /token/refresh  - Access Token 갱신
    POST /logout         - 로그아웃 (Refresh Token 무효화)
=============================================================================
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.auth import (
    get_password_hash,
    create_access_token,
    create_refresh_token,
    authenticate_user,
    verify_refresh_token,
    revoke_refresh_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)
from app.models.user import User
from app.schemas.user import (
    UserCreate, 
    UserResponse, 
    Token,
    TokenWithRefresh,
    TokenRefreshRequest,
)
from app.core.deps import get_db, limiter

router = APIRouter(prefix="", tags=["auth"])


# =============================================================================
# 회원가입
# =============================================================================

@router.post("/register", response_model=UserResponse)
@limiter.limit("5/minute")
async def register_user(
    request: Request,
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    새 사용자 등록
    
    요청 본문:
        - username: 아이디 (3~50자)
        - password: 비밀번호 (6자 이상)
    
    응답:
        - id: 생성된 사용자 ID
        - username: 아이디
        - is_active: 활성 상태
    
    에러:
        - 400: 이미 존재하는 아이디
        - 422: 유효성 검사 실패
        - 429: 요청 한도 초과 (5회/분)
    """
    # 중복 확인
    result = await db.execute(select(User).filter(User.username == user_data.username))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered",
        )

    # 사용자 생성
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        username=user_data.username,
        hashed_password=hashed_password,
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return UserResponse(
        id=str(new_user.id),
        username=new_user.username,
        is_active=new_user.is_active,
    )


# =============================================================================
# 로그인 (토큰 발급)
# =============================================================================

@router.post("/token", response_model=TokenWithRefresh)
@limiter.limit("10/minute")
async def login_for_access_token(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """
    로그인 및 토큰 발급
    
    요청 형식:
        Content-Type: application/x-www-form-urlencoded
        Body: username=아이디&password=비밀번호
    
    응답:
        - access_token: API 요청에 사용 (유효기간: 30분)
        - refresh_token: access_token 갱신에 사용 (유효기간: 7일)
        - token_type: "bearer"
        - expires_in: access_token 만료 시간 (초)
    
    에러:
        - 401: 아이디/비밀번호 오류
        - 429: 요청 한도 초과 (10회/분)
    
    사용 예시:
        1. 로그인 → access_token, refresh_token 받음
        2. API 요청 시 Header에 "Authorization: Bearer {access_token}"
        3. access_token 만료 시 → /token/refresh로 갱신
    """
    # 사용자 인증
    user = await authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Access Token 생성
    access_token = create_access_token(data={"sub": user.username})
    
    # Refresh Token 생성 및 DB 저장
    refresh_token = await create_refresh_token(db, str(user.id))
    
    return TokenWithRefresh(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60  # 초 단위로 변환
    )


# =============================================================================
# 토큰 갱신
# =============================================================================

@router.post("/token/refresh", response_model=Token)
@limiter.limit("30/minute")
async def refresh_access_token(
    request: Request,
    token_request: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Access Token 갱신
    
    언제 사용하나요?
        Access Token이 만료되었을 때!
        매번 로그인하지 않고 Refresh Token으로 새 Access Token을 받습니다.
    
    요청 본문:
        - refresh_token: 로그인 시 받은 Refresh Token
    
    응답:
        - access_token: 새로운 Access Token
        - token_type: "bearer"
    
    에러:
        - 401: Refresh Token이 유효하지 않음 (만료/무효화/잘못된 토큰)
    
    주의사항:
        - Refresh Token은 갱신되지 않습니다 (7일 후 재로그인 필요)
        - 무효화된 Refresh Token으로는 갱신 불가
    """
    # Refresh Token 검증
    user = await verify_refresh_token(db, token_request.refresh_token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 새 Access Token 발급
    new_access_token = create_access_token(data={"sub": user.username})
    
    return Token(
        access_token=new_access_token,
        token_type="bearer"
    )


# =============================================================================
# 로그아웃
# =============================================================================

@router.post("/logout")
@limiter.limit("10/minute")
async def logout(
    request: Request,
    token_request: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    로그아웃 (Refresh Token 무효화)
    
    왜 필요한가요?
        Refresh Token을 무효화하지 않으면, 
        탈취한 사람이 계속 새 Access Token을 발급받을 수 있습니다.
    
    요청 본문:
        - refresh_token: 무효화할 Refresh Token
    
    응답:
        - message: "로그아웃 성공"
    
    참고:
        - Access Token은 서버에서 무효화할 수 없음 (만료까지 유효)
        - 중요한 작업 후에는 클라이언트에서 Access Token도 삭제하세요
    """
    # Refresh Token 무효화
    success = await revoke_refresh_token(db, token_request.refresh_token)
    
    if not success:
        # 토큰이 없어도 에러를 던지지 않음 (이미 로그아웃된 상태일 수 있음)
        pass
    
    return {"message": "로그아웃 성공"}

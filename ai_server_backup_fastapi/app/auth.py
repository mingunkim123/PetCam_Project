"""
=============================================================================
JWT 인증 모듈
=============================================================================

이 파일이 하는 일:
    1. 비밀번호 암호화 (bcrypt)
    2. Access Token 생성/검증 (JWT)
    3. Refresh Token 생성/검증
    4. 현재 로그인한 사용자 확인

JWT가 뭔가요?
    "JSON Web Token"의 약자입니다.
    로그인하면 받는 '디지털 출입증'이라고 생각하면 됩니다.
    
    구조: xxxxx.yyyyy.zzzzz (점으로 구분된 3부분)
    - 헤더: 토큰 타입, 알고리즘
    - 페이로드: 사용자 정보 (username 등)
    - 서명: 위조 방지용 (SECRET_KEY로 생성)
=============================================================================
"""

import os
import secrets
from datetime import datetime, timedelta
from typing import Optional, Tuple

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from database import SessionLocal
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.schemas.user import TokenData


# =============================================================================
# 설정값
# =============================================================================

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise ValueError(
        "SECRET_KEY 환경변수가 설정되지 않았습니다! "
        ".env 파일에 강력한 시크릿 키를 설정하세요. "
        "예: SECRET_KEY=$(openssl rand -hex 32)"
    )

ALGORITHM = "HS256"  # 서명 알고리즘

# Access Token 만료 시간 (분)
# - 짧을수록 안전 (탈취되어도 금방 만료)
# - 기본값: 30분
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

# Refresh Token 만료 시간 (일)
# - 길수록 편리 (자주 로그인 안 해도 됨)
# - 기본값: 7일
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))


# ============ 비밀번호 해싱 ============
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """평문 비밀번호와 해시 비교"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """비밀번호를 bcrypt 해시로 변환"""
    return pwd_context.hash(password)


# ============ JWT 토큰 ============
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    JWT 액세스 토큰 생성

    Args:
        data: 토큰에 포함할 데이터 (예: {"sub": username})
        expires_delta: 만료 시간 (기본: ACCESS_TOKEN_EXPIRE_MINUTES)

    Returns:
        인코딩된 JWT 문자열
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


# ============ DB 세션 의존성 ============
async def get_db():
    """비동기 DB 세션 생성"""
    async with SessionLocal() as db:
        try:
            yield db
        finally:
            await db.close()


# ============ 현재 사용자 조회 ============
async def get_current_user(
    token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)
) -> User:
    """
    JWT 토큰에서 현재 사용자 추출 (FastAPI Dependency)

    - 토큰 검증 실패 시 401 Unauthorized
    - 사용자 미존재 시 401 Unauthorized
    - 비활성 사용자 시 400 Bad Request
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception

    # DB에서 사용자 조회
    result = await db.execute(select(User).filter(User.username == token_data.username))
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user"
        )

    return user


async def authenticate_user(
    db: AsyncSession, username: str, password: str
) -> Optional[User]:
    """
    사용자 인증 (로그인 시 사용)

    Returns:
        인증 성공 시 User 객체, 실패 시 None
    """
    result = await db.execute(select(User).filter(User.username == username))
    user = result.scalar_one_or_none()

    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None

    return user


# =============================================================================
# Refresh Token 관련 함수
# =============================================================================

def generate_refresh_token() -> str:
    """
    랜덤한 Refresh Token 문자열을 생성합니다.
    
    특징:
        - 64바이트 랜덤 문자열 (암호학적으로 안전)
        - URL-safe 문자만 사용 (특수문자 없음)
    
    Returns:
        안전한 랜덤 토큰 문자열
    
    예시:
        "aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9dE1fG3hI5jK7lM9nO1pQ3r"
    """
    return secrets.token_urlsafe(64)


async def create_refresh_token(
    db: AsyncSession, 
    user_id: str
) -> str:
    """
    Refresh Token을 생성하고 DB에 저장합니다.
    
    동작 과정:
        1. 랜덤 토큰 문자열 생성
        2. 만료 시간 계산 (현재 + 7일)
        3. DB에 저장
        4. 토큰 문자열 반환
    
    Args:
        db: 데이터베이스 세션
        user_id: 사용자 ID (UUID)
    
    Returns:
        생성된 Refresh Token 문자열
    """
    # 1. 랜덤 토큰 생성
    token_str = generate_refresh_token()
    
    # 2. 만료 시간 계산
    expires_at = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    
    # 3. DB에 저장
    refresh_token = RefreshToken(
        user_id=user_id,
        token=token_str,
        expires_at=expires_at,
        revoked=False
    )
    db.add(refresh_token)
    await db.commit()
    
    # 4. 토큰 반환
    return token_str


async def verify_refresh_token(
    db: AsyncSession, 
    token_str: str
) -> Optional[User]:
    """
    Refresh Token을 검증하고 해당 사용자를 반환합니다.
    
    검증 과정:
        1. DB에서 토큰 조회
        2. 토큰 존재 여부 확인
        3. 무효화 여부 확인
        4. 만료 여부 확인
        5. 사용자 조회 및 반환
    
    Args:
        db: 데이터베이스 세션
        token_str: 검증할 Refresh Token 문자열
    
    Returns:
        유효하면 User 객체, 무효하면 None
    """
    # 1. DB에서 토큰 조회
    result = await db.execute(
        select(RefreshToken).filter(RefreshToken.token == token_str)
    )
    token_record = result.scalar_one_or_none()
    
    # 2. 토큰이 없으면 None
    if not token_record:
        return None
    
    # 3. 유효성 검사 (무효화, 만료 체크)
    if not token_record.is_valid():
        return None
    
    # 4. 사용자 조회
    user_result = await db.execute(
        select(User).filter(User.id == token_record.user_id)
    )
    user = user_result.scalar_one_or_none()
    
    # 5. 사용자가 없거나 비활성이면 None
    if not user or not user.is_active:
        return None
    
    return user


async def revoke_refresh_token(
    db: AsyncSession, 
    token_str: str
) -> bool:
    """
    Refresh Token을 무효화합니다 (로그아웃 시 사용).
    
    왜 필요한가요?
        사용자가 로그아웃하면 Refresh Token을 더 이상 
        사용할 수 없게 만들어야 합니다.
        그래야 다른 사람이 토큰을 탈취해도 사용할 수 없습니다.
    
    Args:
        db: 데이터베이스 세션
        token_str: 무효화할 토큰 문자열
    
    Returns:
        성공 시 True, 토큰 없으면 False
    """
    result = await db.execute(
        select(RefreshToken).filter(RefreshToken.token == token_str)
    )
    token_record = result.scalar_one_or_none()
    
    if not token_record:
        return False
    
    # revoked를 True로 변경
    token_record.revoked = True
    await db.commit()
    
    return True


async def revoke_all_user_tokens(
    db: AsyncSession, 
    user_id: str
) -> int:
    """
    특정 사용자의 모든 Refresh Token을 무효화합니다.
    
    사용 시나리오:
        - 비밀번호 변경 시 (보안상 모든 기기에서 로그아웃)
        - 계정 해킹 의심 시
        - "모든 기기에서 로그아웃" 기능
    
    Args:
        db: 데이터베이스 세션
        user_id: 사용자 ID
    
    Returns:
        무효화된 토큰 개수
    """
    result = await db.execute(
        select(RefreshToken).filter(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked == False  # 아직 유효한 토큰만
        )
    )
    tokens = result.scalars().all()
    
    count = 0
    for token in tokens:
        token.revoked = True
        count += 1
    
    await db.commit()
    return count

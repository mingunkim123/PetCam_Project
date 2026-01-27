"""
JWT 인증 모듈

- 비밀번호 해싱 (bcrypt)
- JWT 토큰 생성/검증
- FastAPI 의존성 주입용 get_current_user
"""

import os
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from database import SessionLocal
from app.models.user import User
from app.schemas.user import TokenData


# ============ 설정 ============
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise ValueError(
        "SECRET_KEY 환경변수가 설정되지 않았습니다! "
        ".env 파일에 강력한 시크릿 키를 설정하세요. "
        "예: SECRET_KEY=$(openssl rand -hex 32)"
    )

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))


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

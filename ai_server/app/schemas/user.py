"""
User 관련 Pydantic 스키마 (요청/응답 검증)
"""

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    """회원가입 요청 스키마"""

    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)


class UserResponse(BaseModel):
    """사용자 정보 응답 스키마"""

    id: str
    username: str
    is_active: bool

    class Config:
        from_attributes = True


class Token(BaseModel):
    """JWT 토큰 응답 스키마"""

    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """토큰 페이로드 스키마"""

    username: str | None = None

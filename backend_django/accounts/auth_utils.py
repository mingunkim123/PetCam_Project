"""
JWT Access Token 발급·검증, Refresh Token CRUD
"""
import datetime
import secrets

import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

from .models import RefreshToken

User = get_user_model()


def create_access_token(username: str) -> str:
    """
    username을 sub에 넣어 Access Token(JWT) 생성.
    반환: JWT 문자열
    """
    expire_minutes = getattr(settings, 'ACCESS_TOKEN_EXPIRE_MINUTES', 30)
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        'sub': username,
        'exp': now + datetime.timedelta(minutes=expire_minutes),
        'iat': now,
    }
    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm='HS256',
    )


def verify_access_token(token: str) -> str | None:
    """
    JWT 검증 후 sub(username) 반환.
    만료·서명 오류 시 None 반환.
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256'],
        )
        return payload.get('sub')
    except jwt.PyJWTError:
        return None


def create_refresh_token(user: User) -> str:
    """
    Refresh Token 생성 후 DB에 저장.
    반환: token 문자열
    """
    expire_days = getattr(settings, 'REFRESH_TOKEN_EXPIRE_DAYS', 7)
    token = secrets.token_urlsafe(32)
    expires_at = timezone.now() + datetime.timedelta(days=expire_days)
    RefreshToken.objects.create(
        user=user,
        token=token,
        expires_at=expires_at,
    )
    return token


def verify_refresh_token(token: str) -> User | None:
    """
    Refresh Token 검증 후 해당 User 반환.
    만료/무효화/없음 시 None.
    """
    now = timezone.now()
    try:
        rt = RefreshToken.objects.get(token=token)
    except RefreshToken.DoesNotExist:
        return None
    if rt.revoked or rt.expires_at <= now:
        return None
    return rt.user


def revoke_refresh_token(token: str) -> bool:
    """
    해당 Refresh Token 무효화 (revoked=True).
    반환: 무효화 성공 여부 (토큰이 없어도 True)
    """
    updated = RefreshToken.objects.filter(token=token).update(revoked=True)
    return True

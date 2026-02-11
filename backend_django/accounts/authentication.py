"""
DRF JWT 인증 클래스
Authorization: Bearer <token> 헤더에서 JWT를 추출해 request.user 설정
"""
from rest_framework import authentication
from rest_framework import exceptions

from django.contrib.auth import get_user_model

from .auth_utils import verify_access_token

User = get_user_model()


class JWTAuthentication(authentication.BaseAuthentication):
    """
    Bearer JWT로 인증.
    Authorization: Bearer <access_token>
    """

    keyword = "Bearer"

    def authenticate(self, request):
        auth_header = request.META.get("HTTP_AUTHORIZATION")
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0] != self.keyword:
            return None

        token = parts[1]
        username = verify_access_token(token)
        if not username:
            raise exceptions.AuthenticationFailed("Invalid or expired token")

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise exceptions.AuthenticationFailed("User not found")

        if not user.is_active:
            raise exceptions.AuthenticationFailed("User is inactive")

        return (user, token)

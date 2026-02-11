from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth_utils import create_access_token, create_refresh_token, verify_refresh_token, revoke_refresh_token
from .utils import get_password_hash, verify_password

User = get_user_model()


class RegisterView(APIView):
    """POST /register - JSON {username, password}로 회원가입."""
    throttle_scope = "register"

    def post(self, request: Request) -> Response:
        username = request.data.get("username")
        password = request.data.get("password")

        if not username or not password:
            return Response(
                {"detail": "username and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {"detail": "Username already registered"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create(
            username=username,
            password=get_password_hash(password),
        )

        return Response(
            {
                "id": str(user.id),
                "username": user.username,
                "is_active": user.is_active,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """POST /token - form-data username, password로 로그인 → access_token, refresh_token 반환."""
    throttle_scope = "token"

    def post(self, request: Request) -> Response:
        username = request.data.get("username")
        password = request.data.get("password")

        if not username or not password:
            return Response(
                {"detail": "username and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {"detail": "Incorrect username or password"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not verify_password(password, user.password):
            return Response(
                {"detail": "Incorrect username or password"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.is_active:
            return Response(
                {"detail": "User is inactive"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        access_token = create_access_token(user.username)
        refresh_token = create_refresh_token(user)
        expire_minutes = getattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES", 30)
        expires_in = expire_minutes * 60

        return Response({
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": expires_in,
        })


class RefreshTokenView(APIView):
    """POST /token/refresh - JSON {refresh_token}으로 새 access_token 발급."""
    throttle_scope = "refresh"

    def post(self, request: Request) -> Response:
        refresh_token = request.data.get("refresh_token")

        if not refresh_token:
            return Response(
                {"detail": "refresh_token is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = verify_refresh_token(refresh_token)
        if not user:
            return Response(
                {"detail": "Invalid or expired refresh token"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        access_token = create_access_token(user.username)
        return Response({
            "access_token": access_token,
            "token_type": "bearer",
        })


class LogoutView(APIView):
    """POST /logout - JSON {refresh_token}으로 해당 토큰 무효화."""
    throttle_scope = "logout"

    def post(self, request: Request) -> Response:
        refresh_token = request.data.get("refresh_token")
        if refresh_token:
            revoke_refresh_token(refresh_token)
        return Response({"message": "로그아웃 성공"})

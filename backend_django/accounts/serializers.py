"""
accounts 앱 Serializer

왜 Serializer를 사용하는가?
- DRF의 핵심 설계 원칙: 입력 검증(validation)과 출력 직렬화(serialization)를 한 곳에서 관리
- View가 "어떤 데이터를 받고 어떤 데이터를 보내는지"를 Serializer에 위임
- Swagger/OpenAPI 문서를 자동 생성할 때 Serializer가 기준이 됨

대안: Django Form → API에서는 Serializer가 업계 표준
"""

from django.contrib.auth import get_user_model
from rest_framework import serializers

User = get_user_model()


# ==========================================
# 입력(Input) Serializers
# ==========================================


class RegisterSerializer(serializers.Serializer):
    """회원가입 요청 데이터 검증."""

    username = serializers.CharField(
        max_length=150,
        help_text="사용자 이름 (1~150자)",
    )
    password = serializers.CharField(
        min_length=4,
        write_only=True,
        help_text="비밀번호 (4자 이상)",
    )

    def validate_username(self, value):
        """username 중복 체크."""
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username already registered")
        return value


class LoginSerializer(serializers.Serializer):
    """로그인 요청 데이터 검증."""

    username = serializers.CharField()
    password = serializers.CharField(write_only=True)


class RefreshTokenSerializer(serializers.Serializer):
    """토큰 갱신 요청 데이터 검증."""

    refresh_token = serializers.CharField()


class LogoutSerializer(serializers.Serializer):
    """로그아웃 요청 데이터 검증."""

    refresh_token = serializers.CharField(required=False)


# ==========================================
# 출력(Output) Serializers
# ==========================================


class UserResponseSerializer(serializers.Serializer):
    """회원가입 응답 직렬화."""

    id = serializers.UUIDField()
    username = serializers.CharField()
    is_active = serializers.BooleanField()


class TokenResponseSerializer(serializers.Serializer):
    """로그인 응답 직렬화."""

    access_token = serializers.CharField()
    refresh_token = serializers.CharField()
    token_type = serializers.CharField(default="bearer")
    expires_in = serializers.IntegerField(help_text="토큰 만료 시간 (초)")


class AccessTokenResponseSerializer(serializers.Serializer):
    """토큰 갱신 응답 직렬화."""

    access_token = serializers.CharField()
    token_type = serializers.CharField(default="bearer")

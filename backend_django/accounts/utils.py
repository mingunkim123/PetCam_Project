"""
비밀번호 해시 (Django bcrypt)
Django User 모델과 호환되는 형식으로 저장.
"""
from django.contrib.auth.hashers import check_password
from django.contrib.auth.hashers import make_password


def get_password_hash(password: str) -> str:
    """비밀번호를 bcrypt로 해시 (Django 형식)."""
    return make_password(password, hasher="bcrypt_sha256")


def verify_password(plain: str, hashed: str) -> bool:
    """평문 비밀번호와 해시 비교."""
    return check_password(plain, hashed)

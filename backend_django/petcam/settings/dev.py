"""
개발 환경 설정
DEBUG=True, ALLOWED_HOSTS 허용적
환경변수 없으면 기본값 사용
"""

from .base import *

DEBUG = env.bool('DEBUG', default=True)

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1', '0.0.0.0', 'testserver'])

SECRET_KEY = env('SECRET_KEY', default='django-insecure-dev-key-change-in-production')

# 개발 시 모든 오리진 허용 (프로덕션에서는 CORS_ALLOWED_ORIGINS 사용)
CORS_ALLOW_ALL_ORIGINS = True

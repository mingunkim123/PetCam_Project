"""
프로덕션 환경 설정
DEBUG=False, SECRET_KEY·ALLOWED_HOSTS는 환경변수 필수
"""

from .base import *

DEBUG = env.bool('DEBUG', default=False)

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])

SECRET_KEY = env('SECRET_KEY')  # 프로덕션에서는 .env에 반드시 설정

# CORS: 프로덕션에서는 허용 오리진을 명시 (CORS_ALLOW_ALL_ORIGINS=False)
# CORS_ALLOWED_ORIGINS=http://localhost:3000,https://example.com
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])

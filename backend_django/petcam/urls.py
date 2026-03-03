"""
PetCam URL Configuration

API 버저닝: /api/v1/ prefix 사용
- /api/v1/auth/   → accounts 앱 (인증 관련)
- /api/v1/photos/ → photos 앱 (사진 관련)
- /api/health/    → 서버 상태 확인
"""

from django.contrib import admin
from django.urls import path, include

from .views import HealthView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthView.as_view(), name="health"),
    path("api/v1/auth/", include("accounts.urls")),
    path("api/v1/photos/", include("photos.urls")),
]

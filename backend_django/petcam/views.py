"""프로젝트 공통 뷰"""
from django.http import JsonResponse


def health_view(request):
    """GET /health - 서버 상태 확인."""
    return JsonResponse({"status": "ok", "version": "1.0.0"})

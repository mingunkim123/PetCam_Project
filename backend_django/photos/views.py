import os
import threading
import uuid
from pathlib import Path

from django.conf import settings
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.authentication import JWTAuthentication
from services.ai_service import run_ai_task

from .models import PhotoRecord, ProcessingStatus

STORAGE_ORIGINALS = Path(settings.BASE_DIR) / "storage" / "originals"


def _get_blur_score(path: str) -> float:
    """Laplacian variance로 선명도(blur 반대) 점수 계산. 높을수록 선명함."""
    import cv2
    img = cv2.imread(path)
    if img is None:
        return -1.0
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


class UpscaleView(APIView):
    """POST /upscale - multipart file, lat, lng로 이미지 업로드."""
    authentication_classes = [JWTAuthentication]
    throttle_scope = "upscale_bestcut"

    def post(self, request: Request) -> Response:
        uploaded_file = request.FILES.get("file")
        if not uploaded_file:
            return Response(
                {"detail": "file is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        lat = float(request.data.get("lat", 0.0))
        lng = float(request.data.get("lng", 0.0))

        photo_id = uuid.uuid4()
        STORAGE_ORIGINALS.mkdir(parents=True, exist_ok=True)
        orig_path = STORAGE_ORIGINALS / f"{photo_id}.jpg"

        try:
            with open(orig_path, "wb") as f:
                for chunk in uploaded_file.chunks():
                    f.write(chunk)
        except OSError as e:
            return Response(
                {"detail": f"File save failed: {e}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        record = PhotoRecord.objects.create(
            id=photo_id,
            user=request.user,
            original_path=str(orig_path),
            status=ProcessingStatus.QUEUED,
            latitude=lat,
            longitude=lng,
        )

        threading.Thread(target=run_ai_task, args=(str(photo_id),), daemon=True).start()

        return Response(
            {
                "message": "Upload successful, processing in background",
                "id": str(record.id),
            },
            status=status.HTTP_201_CREATED,
        )


class BestCutView(APIView):
    """POST /bestcut - 다중 파일 중 블러 점수 최고 파일만 남기고 PhotoRecord 생성."""
    authentication_classes = [JWTAuthentication]
    throttle_scope = "upscale_bestcut"

    def post(self, request: Request) -> Response:
        files = request.FILES.getlist("files")
        if not files:
            return Response(
                {"detail": "files are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        lat = float(request.data.get("lat", 0.0))
        lng = float(request.data.get("lng", 0.0))

        STORAGE_ORIGINALS.mkdir(parents=True, exist_ok=True)
        temp_dir = STORAGE_ORIGINALS / "temp"
        temp_dir.mkdir(exist_ok=True)

        temp_paths = []
        best_score = -1.0
        best_path = None

        try:
            for f in files:
                temp_id = uuid.uuid4()
                temp_path = temp_dir / f"temp_{temp_id}.jpg"
                with open(temp_path, "wb") as out:
                    for chunk in f.chunks():
                        out.write(chunk)
                temp_paths.append(temp_path)
                score = _get_blur_score(str(temp_path))
                if score > best_score:
                    best_score = score
                    best_path = temp_path

            if best_path is None:
                return Response(
                    {"detail": "No valid images found"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            photo_id = uuid.uuid4()
            final_path = STORAGE_ORIGINALS / f"{photo_id}.jpg"
            os.rename(best_path, final_path)

            for p in temp_paths:
                if p.exists() and p != best_path:
                    p.unlink()

            record = PhotoRecord.objects.create(
                id=photo_id,
                user=request.user,
                original_path=str(final_path),
                status=ProcessingStatus.QUEUED,
                latitude=lat,
                longitude=lng,
            )

            threading.Thread(target=run_ai_task, args=(str(photo_id),), daemon=True).start()

            return Response(
                {
                    "message": "Best cut selected, processing in background",
                    "id": str(record.id),
                    "score": best_score,
                },
                status=status.HTTP_201_CREATED,
            )
        finally:
            for p in temp_paths:
                if p.exists():
                    try:
                        p.unlink()
                    except OSError:
                        pass


class PhotoListView(APIView):
    """GET /photos?skip=0&limit=100 - 사진 목록."""
    authentication_classes = [JWTAuthentication]
    throttle_scope = "photos"

    def get(self, request: Request) -> Response:
        skip = int(request.query_params.get("skip", 0))
        limit = min(int(request.query_params.get("limit", 100)), 1000)
        qs = PhotoRecord.objects.filter(user=request.user).order_by("-created_at")
        records = list(qs[skip : skip + limit])
        data = [
            {
                "id": str(r.id),
                "original_path": r.original_path,
                "upscaled_path": r.upscaled_path,
                "status": r.status,
                "latitude": r.latitude,
                "longitude": r.longitude,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in records
        ]
        return Response(data)


class PhotoDetailView(APIView):
    """GET /photos/{id}?type=upscaled - 이미지 파일, DELETE /photos/{id} - 삭제."""
    authentication_classes = [JWTAuthentication]
    throttle_scope = "photos"

    def get(self, request: Request, photo_id: uuid.UUID) -> Response:
        try:
            record = PhotoRecord.objects.get(id=photo_id, user=request.user)
        except PhotoRecord.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        use_upscaled = request.query_params.get("type") == "upscaled"
        path = record.upscaled_path if use_upscaled else record.original_path
        if use_upscaled and (not path or not os.path.exists(path)):
            path = record.original_path
        if not path or not os.path.exists(path):
            return Response(status=status.HTTP_404_NOT_FOUND)

        with open(path, "rb") as f:
            return Response(f.read(), content_type="image/jpeg")

    def delete(self, request: Request, photo_id: uuid.UUID) -> Response:
        try:
            record = PhotoRecord.objects.get(id=photo_id, user=request.user)
        except PhotoRecord.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        if record.original_path and os.path.exists(record.original_path):
            os.remove(record.original_path)
        if record.upscaled_path and os.path.exists(record.upscaled_path):
            os.remove(record.upscaled_path)
        record.delete()
        return Response({"message": "Deleted successfully"})

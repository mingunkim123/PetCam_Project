import uuid

from django.conf import settings
from django.db import models


class ProcessingStatus(models.TextChoices):
    UPLOADED = "uploaded", "업로드됨"
    QUEUED = "queued", "대기중"
    PROCESSING = "processing", "처리중"
    COMPLETED = "completed", "완료"
    FAILED = "failed", "실패"


class PhotoRecord(models.Model):
    """사진 업로드 및 업스케일 처리 기록."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="photos",
    )
    original_path = models.CharField(max_length=512)
    upscaled_path = models.CharField(max_length=512, null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=ProcessingStatus.choices,
        default=ProcessingStatus.QUEUED,
    )
    error_message = models.CharField(max_length=512, null=True, blank=True)
    latitude = models.FloatField(default=0.0)
    longitude = models.FloatField(default=0.0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "photos_photorecord"
        ordering = ["-created_at"]

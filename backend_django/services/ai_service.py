"""
AI 이미지 처리 서비스
- RealESRGAN 업스케일링 (선택)
- process_image_sync: 동기식 이미지 처리
- run_ai_task: 백그라운드 스레드에서 실행할 태스크 (DB 업데이트 포함)
"""

from pathlib import Path

from django.conf import settings
from django.db import close_old_connections
from PIL import Image

# RealESRGAN import (모듈·가중치 없으면 None → PIL BICUBIC fallback)
_REALESRGAN_AVAILABLE = False
_model = None
try:
    import torch
    from RealESRGAN import RealESRGAN

    weights_path = Path(settings.BASE_DIR).parent / "ai_server" / "weights" / "RealESRGAN_x4.pth"
    if weights_path.exists():
        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        _model = RealESRGAN(_device, scale=4)
        _model.load_weights(str(weights_path))
        _REALESRGAN_AVAILABLE = True
        print("✅ RealESRGAN model loaded successfully!")
    else:
        print("⚠️ RealESRGAN weights not found, using fallback resize.")
except Exception as e:
    print(f"⚠️ RealESRGAN not available ({e}), using fallback resize.")


def process_image_sync(original_path: str, res_path: str) -> None:
    """
    동기식 AI 처리 (별도 스레드에서 실행됨)
    - RealESRGAN 있으면 4x 업스케일, 없으면 PIL BICUBIC 4배 리사이즈
    """
    Path(res_path).parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(original_path).convert("RGB")

    # [OOM 방지] 이미지 크기 조정 (Max 1080px)
    max_size = 1080
    if image.width > max_size or image.height > max_size:
        image.thumbnail((max_size, max_size), Image.LANCZOS)

    if _model and _REALESRGAN_AVAILABLE:
        import torch

        torch.cuda.empty_cache()
        with torch.no_grad():
            sr_image = _model.predict(image)
        torch.cuda.empty_cache()
    else:
        # Fallback: 모델 없으면 4배 리사이즈
        new_size = (image.width * 4, image.height * 4)
        sr_image = image.resize(new_size, Image.BICUBIC)

    sr_image.save(res_path, format="JPEG")


def run_ai_task(photo_id: str) -> None:
    """
    백그라운드 스레드에서 실행할 AI 처리 태스크.
    - status: QUEUED → PROCESSING → COMPLETED or FAILED
    - 완료 시 upscaled_path 저장
    """
    # Django 스레드에서 DB 사용 시 연결 정리
    close_old_connections()

    from photos.models import PhotoRecord, ProcessingStatus

    try:
        record = PhotoRecord.objects.get(id=photo_id)
    except PhotoRecord.DoesNotExist:
        return

    original_path = record.original_path
    if not original_path or not Path(original_path).exists():
        record.status = ProcessingStatus.FAILED
        record.error_message = "Original image not found"
        record.save()
        close_old_connections()
        return

    results_dir = Path(settings.BASE_DIR) / "storage" / "results"
    results_dir.mkdir(parents=True, exist_ok=True)
    res_path = str(results_dir / f"{photo_id}.jpg")

    try:
        # 1. PROCESSING
        record.status = ProcessingStatus.PROCESSING
        record.save(update_fields=["status"])
        close_old_connections()

        # 2. AI 처리
        process_image_sync(original_path, res_path)

        # 3. COMPLETED
        close_old_connections()
        record = PhotoRecord.objects.get(id=photo_id)
        record.upscaled_path = res_path
        record.status = ProcessingStatus.COMPLETED
        record.error_message = None
        record.save(update_fields=["upscaled_path", "status", "error_message"])
    except Exception as e:
        close_old_connections()
        try:
            record = PhotoRecord.objects.get(id=photo_id)
            record.status = ProcessingStatus.FAILED
            record.error_message = str(e)[:512]
            record.save(update_fields=["status", "error_message"])
        except Exception:
            pass
        print(f"❌ [Background] Error processing {photo_id}: {e}")

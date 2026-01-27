"""
AI 이미지 처리 서비스
- RealESRGAN 업스케일링
- 블러 점수 계산
- 백그라운드 처리 태스크
"""

import asyncio
from functools import partial

import cv2
import torch
from PIL import Image
from sqlalchemy.future import select

from database import SessionLocal
from models import PhotoRecord, ProcessingStatus

# RealESRGAN import (모듈 없으면 None)
try:
    from RealESRGAN import RealESRGAN
except ImportError:
    RealESRGAN = None
    print("⚠️ Warning: RealESRGAN module not found. AI features will be disabled.")

# GPU 가속 설정
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = None

if RealESRGAN:
    try:
        model = RealESRGAN(device, scale=4)
        model.load_weights("weights/RealESRGAN_x4.pth", download=True)
        print("✅ RealESRGAN model loaded successfully!")
    except Exception as e:
        print(f"❌ Error loading RealESRGAN: {e}")


def get_blur_score_sync(image_path: str) -> float:
    """동기식 Blur Score 계산 (별도 스레드에서 실행됨)"""
    try:
        img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.0
        return cv2.Laplacian(img, cv2.CV_64F).var()
    except Exception as e:
        print(f"Error calculating blur score: {e}")
        return 0.0


def process_image_sync(original_path: str, res_path: str):
    """동기식 AI 처리 (별도 스레드에서 실행됨)"""
    try:
        image = Image.open(original_path).convert("RGB")

        # [OOM 방지] 이미지 크기 조정 (Max 1080px)
        max_size = 1080
        if image.width > max_size or image.height > max_size:
            image.thumbnail((max_size, max_size), Image.LANCZOS)

        if model:
            # RealESRGAN 처리
            torch.cuda.empty_cache()
            with torch.no_grad():
                sr_image = model.predict(image)
            torch.cuda.empty_cache()
        else:
            # Fallback: 모델 없으면 4배 리사이즈
            print("⚠️ RealESRGAN not available, using fallback resize.")
            new_size = (image.width * 4, image.height * 4)
            sr_image = image.resize(new_size, Image.BICUBIC)

        sr_image.save(res_path, format="JPEG")
        return True
    except Exception as e:
        print(f"AI Processing Error: {e}")
        raise e


async def process_image_task(photo_id: str, original_path: str):
    """백그라운드에서 실행될 AI 처리 작업 (Non-blocking)"""
    print(f"🔄 [Background] Processing photo {photo_id} started...")

    try:
        async with SessionLocal() as db:
            # 0. 상태 업데이트: PROCESSING
            result = await db.execute(
                select(PhotoRecord).filter(PhotoRecord.id == photo_id)
            )
            record = result.scalar_one_or_none()
            if record:
                record.status = ProcessingStatus.PROCESSING
                await db.commit()

            # 1. AI 처리 (Blocking 함수를 Executor에서 실행)
            loop = asyncio.get_running_loop()
            res_path = f"storage/results/{photo_id}.jpg"

            await loop.run_in_executor(
                None, partial(process_image_sync, original_path, res_path)
            )

            # 2. DB 업데이트: COMPLETED
            result = await db.execute(
                select(PhotoRecord).filter(PhotoRecord.id == photo_id)
            )
            record = result.scalar_one_or_none()
            if record:
                record.upscaled_path = res_path
                record.status = ProcessingStatus.COMPLETED
                await db.commit()

            print(f"✅ [Background] Processing photo {photo_id} completed!")

    except Exception as e:
        print(f"❌ [Background] Error processing {photo_id}: {e}")
        try:
            async with SessionLocal() as db:
                result = await db.execute(
                    select(PhotoRecord).filter(PhotoRecord.id == photo_id)
                )
                record = result.scalar_one_or_none()
                if record:
                    record.status = ProcessingStatus.FAILED
                    record.error_message = str(e)
                    await db.commit()
        except Exception as db_e:
            print(f"❌ [Background] Failed to update error status: {db_e}")

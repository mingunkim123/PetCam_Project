"""
사진 관련 API 라우터 (/upscale, /bestcut, /photos)
"""

import os
import uuid
import shutil
import asyncio
from typing import List

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    BackgroundTasks,
    UploadFile,
    File,
    Query,
    Request,
)
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from models import PhotoRecord, ProcessingStatus
from app.core.deps import get_db, limiter
from app.services.ai_service import process_image_task, get_blur_score_sync
from app.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="", tags=["photos"])


@router.post("/upscale")
@limiter.limit("10/minute")
async def upscale_image(
    request: Request,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    lat: float = 0.0,
    lng: float = 0.0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    photo_id = str(uuid.uuid4())
    orig_path = f"storage/originals/{photo_id}.jpg"

    try:
        with open(orig_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"File save failed: {e}")
    finally:
        file.file.close()

    db_record = PhotoRecord(
        id=photo_id,
        original_path=orig_path,
        upscaled_path=None,
        status=ProcessingStatus.QUEUED,
        latitude=lat,
        longitude=lng,
    )
    db.add(db_record)
    await db.commit()

    background_tasks.add_task(process_image_task, photo_id, orig_path)

    return {"message": "Upload successful, processing in background", "id": photo_id}


@router.post("/bestcut")
@limiter.limit("10/minute")
async def process_best_cut(
    request: Request,
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...),
    lat: float = 0.0,
    lng: float = 0.0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    loop = asyncio.get_running_loop()
    best_score = -1.0
    best_file_path = None
    temp_files = []

    try:
        for file in files:
            temp_id = str(uuid.uuid4())
            temp_path = f"storage/originals/temp_{temp_id}.jpg"

            with open(temp_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            file.file.close()
            temp_files.append(temp_path)

            score = await loop.run_in_executor(None, get_blur_score_sync, temp_path)

            if score > best_score:
                best_score = score
                best_file_path = temp_path

        if best_file_path:
            photo_id = str(uuid.uuid4())
            final_path = f"storage/originals/{photo_id}.jpg"

            os.rename(best_file_path, final_path)

            for path in temp_files:
                if path != best_file_path and os.path.exists(path):
                    os.remove(path)

            db_record = PhotoRecord(
                id=photo_id,
                original_path=final_path,
                upscaled_path=None,
                status=ProcessingStatus.QUEUED,
                latitude=lat,
                longitude=lng,
            )
            db.add(db_record)
            await db.commit()

            background_tasks.add_task(process_image_task, photo_id, final_path)

            return {
                "message": "Best cut selected, processing in background",
                "id": photo_id,
                "score": best_score,
            }

    except Exception as e:
        for path in temp_files:
            if os.path.exists(path):
                os.remove(path)
        raise HTTPException(status_code=500, detail=f"Processing failed: {e}")

    return {"error": "No valid images found"}


@router.get("/photos")
@limiter.limit("60/minute")
async def get_photos(
    request: Request,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(PhotoRecord)
        .order_by(PhotoRecord.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    photos = result.scalars().all()
    return photos


@router.get("/photos/{photo_id}")
async def get_photo_file(
    photo_id: str,
    type: str = "upscaled",
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(PhotoRecord).filter(PhotoRecord.id == photo_id))
    record = result.scalar_one_or_none()
    if not record:
        return Response(status_code=404)

    file_path = record.upscaled_path if type == "upscaled" else record.original_path

    if type == "upscaled" and (file_path is None or not os.path.exists(file_path)):
        file_path = record.original_path

    if not file_path or not os.path.exists(file_path):
        return Response(status_code=404)

    with open(file_path, "rb") as f:
        return Response(content=f.read(), media_type="image/jpeg")


@router.delete("/photos/{photo_id}")
async def delete_photo(
    photo_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(PhotoRecord).filter(PhotoRecord.id == photo_id))
    record = result.scalar_one_or_none()
    if not record:
        return Response(status_code=404)

    if record.original_path and os.path.exists(record.original_path):
        os.remove(record.original_path)
    if record.upscaled_path and os.path.exists(record.upscaled_path):
        os.remove(record.upscaled_path)

    await db.delete(record)
    await db.commit()

    return {"message": "Deleted successfully"}

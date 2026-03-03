from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session
from typing import List
import uuid
import io
import os

from app.api import deps
from app.services.image_service import image_service
from app.models.photo import PhotoRecord
from app.core.config import settings

router = APIRouter()


def save_and_record(db: Session, contents: bytes, sr_image) -> bytes:
    photo_id = str(uuid.uuid4())

    # Save original
    orig_filename = f"{photo_id}.jpg"
    orig_path = os.path.join(settings.ORIGINALS_DIR, orig_filename)
    with open(orig_path, "wb") as f:
        f.write(contents)

    # Save result
    res_filename = f"{photo_id}.jpg"
    res_path = os.path.join(settings.RESULTS_DIR, res_filename)
    sr_image.save(res_path, format="JPEG")

    # DB Record
    db_record = PhotoRecord(
        id=photo_id,
        original_path=orig_path,
        upscaled_path=res_path,
        is_ai_processed=True,
    )
    db.add(db_record)
    db.commit()
    db.refresh(db_record)

    # Return bytes
    img_byte_arr = io.BytesIO()
    sr_image.save(img_byte_arr, format="JPEG")
    return img_byte_arr.getvalue()


@router.post("/upscale")
def upscale_image(file: UploadFile = File(...), db: Session = Depends(deps.get_db)):
    contents = file.file.read()
    sr_image = image_service.upscale_image(contents)
    result_bytes = save_and_record(db, contents, sr_image)
    return Response(content=result_bytes, media_type="image/jpeg")


@router.post("/bestcut")
def process_best_cut(
    files: List[UploadFile] = File(...), db: Session = Depends(deps.get_db)
):
    best_score = -1.0
    best_content = None

    for file in files:
        contents = file.file.read()
        score = image_service.get_blur_score(contents)
        if score > best_score:
            best_score = score
            best_content = contents

    if best_content:
        sr_image = image_service.upscale_image(best_content)
        result_bytes = save_and_record(db, best_content, sr_image)
        return Response(content=result_bytes, media_type="image/jpeg")

    raise HTTPException(status_code=400, detail="Processing failed")

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session
from typing import List
import os

from app.api import deps
from app.models.photo import PhotoRecord
from app.schemas.photo import PhotoResponse

router = APIRouter()


@router.get("/", response_model=List[PhotoResponse])
def get_photos(db: Session = Depends(deps.get_db)):
    """Get all photos ordered by creation time."""
    photos = db.query(PhotoRecord).order_by(PhotoRecord.created_at.desc()).all()
    return photos


@router.get("/{photo_id}")
def get_photo_file(
    photo_id: str, type: str = "upscaled", db: Session = Depends(deps.get_db)
):
    """Get photo file content (original or upscaled)."""
    record = db.query(PhotoRecord).filter(PhotoRecord.id == photo_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Photo not found")

    file_path = record.upscaled_path if type == "upscaled" else record.original_path

    if not file_path or not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found on server")

    with open(file_path, "rb") as f:
        return Response(content=f.read(), media_type="image/jpeg")


@router.delete("/{photo_id}")
def delete_photo(photo_id: str, db: Session = Depends(deps.get_db)):
    """Delete photo record and associated files."""
    record = db.query(PhotoRecord).filter(PhotoRecord.id == photo_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Photo not found")

    # Delete files
    if record.original_path and os.path.exists(record.original_path):
        os.remove(record.original_path)
    if record.upscaled_path and os.path.exists(record.upscaled_path):
        os.remove(record.upscaled_path)

    # Delete DB record
    db.delete(record)
    db.commit()

    return {"message": "Deleted successfully"}

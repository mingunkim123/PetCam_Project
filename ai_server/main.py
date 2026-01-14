from fastapi import FastAPI, UploadFile, File, Depends, BackgroundTasks
from fastapi.responses import Response
import torch
from PIL import Image
import io
import cv2
import numpy as np
from RealESRGAN import RealESRGAN
from typing import List
import os
import uuid
import datetime

# --- [DB 추가 부분] ---
from sqlalchemy.orm import Session
from database import Base, engine, SessionLocal
from sqlalchemy import Column, String, Boolean, DateTime, Float


# DB 테이블 정의 (C++의 struct와 매칭)
class PhotoRecord(Base):
    __tablename__ = "photos"
    id = Column(String, primary_key=True, index=True)
    original_path = Column(String)
    upscaled_path = Column(String, nullable=True)
    is_ai_processed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    latitude = Column(Float, nullable=True)  # 📍 위도 추가
    longitude = Column(Float, nullable=True)  # 📍 경도 추가


# 서버 실행 시 테이블 생성
Base.metadata.create_all(bind=engine)


# DB 세션 의존성 주입 (C++의 GetDBConnection() 역할)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ----------------------

app = FastAPI()

# GPU 가속 설정 (RTX 3060 환경 최적화)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = RealESRGAN(device, scale=4)
model.load_weights("weights/RealESRGAN_x4.pth", download=True)


def get_blur_score(image_bytes):
    """라플라시안 변산으로 선명도 측정: $score = \sigma^2(\nabla^2 I)$"""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return 0
    return cv2.Laplacian(img, cv2.CV_64F).var()


def process_image_task(photo_id: str, original_path: str):
    """백그라운드에서 실행될 AI 처리 작업"""
    print(f"🔄 [Background] Processing photo {photo_id} started...")

    try:
        # DB 세션 생성 (백그라운드 작업용)
        db = SessionLocal()

        # 1. 이미지 로드
        image = Image.open(original_path).convert("RGB")

        # [OOM 방지] 이미지 크기 조정 (Max 1080px)
        max_size = 1080
        if image.width > max_size or image.height > max_size:
            image.thumbnail((max_size, max_size), Image.LANCZOS)

        # 2. AI 처리
        torch.cuda.empty_cache()
        with torch.no_grad():
            sr_image = model.predict(image)
        torch.cuda.empty_cache()

        # 3. 결과 저장
        res_path = f"storage/results/{photo_id}.jpg"
        sr_image.save(res_path, format="JPEG")

        # 4. DB 업데이트
        record = db.query(PhotoRecord).filter(PhotoRecord.id == photo_id).first()
        if record:
            record.upscaled_path = res_path
            record.is_ai_processed = True
            db.commit()
            print(f"✅ [Background] Processing photo {photo_id} completed!")
        else:
            print(f"❌ [Background] Record not found for {photo_id}")

        db.close()

    except Exception as e:
        print(f"❌ [Background] Error processing {photo_id}: {e}")


@app.post("/upscale")
def upscale_image(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    lat: float = 0.0,  # 📍 쿼리 파라미터 추가
    lng: float = 0.0,  # 📍 쿼리 파라미터 추가
    db: Session = Depends(get_db),
):
    contents = file.file.read()
    photo_id = str(uuid.uuid4())  # 고유 ID 생성

    # 1. 원본 저장 (즉시 수행)
    orig_path = f"storage/originals/{photo_id}.jpg"
    with open(orig_path, "wb") as f:
        f.write(contents)

    # 2. DB 기록 (처리 전 상태로 저장)
    db_record = PhotoRecord(
        id=photo_id,
        original_path=orig_path,
        upscaled_path=None,  # 아직 없음
        is_ai_processed=False,  # 처리 대기 중
        latitude=lat,
        longitude=lng,
    )
    db.add(db_record)
    db.commit()

    # 3. 백그라운드 작업 등록 (AI 처리는 나중에)
    background_tasks.add_task(process_image_task, photo_id, orig_path)

    # 4. 즉시 응답 (202 Accepted 느낌으로)
    return {"message": "Upload successful, processing in background", "id": photo_id}


@app.post("/bestcut")
def process_best_cut(
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...),
    lat: float = 0.0,
    lng: float = 0.0,
    db: Session = Depends(get_db),
):
    # Best Cut 선별은 CPU 연산이라 비교적 빠르므로 여기서 수행해도 됨
    # (하지만 파일이 많으면 이것도 백그라운드로 뺄 수 있음. 일단은 유지)

    best_score = -1.0
    best_content = None

    for file in files:
        contents = file.file.read()
        score = get_blur_score(contents)
        if score > best_score:
            best_score = score
            best_content = contents

    if best_content:
        photo_id = str(uuid.uuid4())
        orig_path = f"storage/originals/{photo_id}.jpg"

        # 1. 원본 저장
        with open(orig_path, "wb") as f:
            f.write(best_content)

        # 2. DB 기록
        db_record = PhotoRecord(
            id=photo_id,
            original_path=orig_path,
            upscaled_path=None,
            is_ai_processed=False,
            latitude=lat,
            longitude=lng,
        )
        db.add(db_record)
        db.commit()

        # 3. 백그라운드 작업 등록
        background_tasks.add_task(process_image_task, photo_id, orig_path)

        return {
            "message": "Best cut selected, processing in background",
            "id": photo_id,
        }

    return {"error": "Processing failed"}


@app.get("/photos")
def get_photos(db: Session = Depends(get_db)):
    """DB에 저장된 모든 사진 목록 반환"""
    photos = db.query(PhotoRecord).order_by(PhotoRecord.created_at.desc()).all()
    return photos


@app.get("/photos/{photo_id}")
def get_photo_file(
    photo_id: str, type: str = "upscaled", db: Session = Depends(get_db)
):
    """사진 파일 제공 (type='original' or 'upscaled')"""
    record = db.query(PhotoRecord).filter(PhotoRecord.id == photo_id).first()
    if not record:
        return Response(status_code=404)

    # 요청한 타입의 경로 확인
    file_path = record.upscaled_path if type == "upscaled" else record.original_path

    # 만약 업스케일링된 파일이 아직 없으면(처리 중이면) 원본을 대신 줌 (Fallback)
    if type == "upscaled" and (file_path is None or not os.path.exists(file_path)):
        file_path = record.original_path

    if not file_path or not os.path.exists(file_path):
        return Response(status_code=404)

    with open(file_path, "rb") as f:
        return Response(content=f.read(), media_type="image/jpeg")


@app.delete("/photos/{photo_id}")
def delete_photo(photo_id: str, db: Session = Depends(get_db)):
    """사진 삭제 (DB + 파일)"""
    record = db.query(PhotoRecord).filter(PhotoRecord.id == photo_id).first()
    if not record:
        return Response(status_code=404)

    # 1. 파일 삭제
    if record.original_path and os.path.exists(record.original_path):
        os.remove(record.original_path)
    if record.upscaled_path and os.path.exists(record.upscaled_path):
        os.remove(record.upscaled_path)

    # 2. DB 삭제
    db.delete(record)
    db.commit()

    return {"message": "Deleted successfully"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

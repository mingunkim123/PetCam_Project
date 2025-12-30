from fastapi import FastAPI, UploadFile, File
from fastapi.responses import Response
import torch
from PIL import Image
import io
import cv2
import numpy as np
from RealESRGAN import RealESRGAN
from typing import List

app = FastAPI()

# 💡 GPU (RTX 3060) 가속 설정
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = RealESRGAN(device, scale=4)
model.load_weights('weights/RealESRGAN_x4.pth', download=True)

def get_blur_score(image_bytes):
    """라플라시안 변산(Variance of Laplacian)으로 선명도 측정"""
    # 💡 수식: $score = \sigma^2(\nabla^2 I)$
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    if img is None: return 0
    return cv2.Laplacian(img, cv2.CV_64F).var()

@app.post("/upscale")
async def upscale_image(file: UploadFile = File(...)):
    contents = await file.read()
    image = Image.open(io.BytesIO(contents)).convert('RGB')
    sr_image = model.predict(image)
    
    img_byte_arr = io.BytesIO()
    sr_image.save(img_byte_arr, format='JPEG')
    return Response(content=img_byte_arr.getvalue(), media_type="image/jpeg")

@app.post("/bestcut")
async def process_best_cut(files: List[UploadFile] = File(...)):
    best_score = -1.0
    best_content = None
    
    print(f"📸 {len(files)}장의 연속 사진 분석 중...")
    for file in files:
        contents = await file.read()
        score = get_blur_score(contents)
        print(f"   - {file.filename}: 점수 {score:.2f}")
        if score > best_score:
            best_score = score
            best_content = contents

    if best_content:
        print(f"🏆 베스트 컷 선정 완료 ({best_score:.2f}) -> 업스케일링 시작")
        image = Image.open(io.BytesIO(best_content)).convert('RGB')
        sr_image = model.predict(image)
        
        out_buffer = io.BytesIO()
        sr_image.save(out_buffer, format='JPEG')
        return Response(content=out_buffer.getvalue(), media_type="image/jpeg")
    
    return {"error": "Processing failed"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
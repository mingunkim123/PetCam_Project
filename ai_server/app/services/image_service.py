import torch
import cv2
import numpy as np
from PIL import Image
import io
from app.core.config import settings
import os

try:
    from RealESRGAN import RealESRGAN
except ImportError:
    RealESRGAN = None
    print("Warning: RealESRGAN module not found. AI features will be disabled.")


class ImageService:
    _instance = None
    _model = None
    _device = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ImageService, cls).__new__(cls)
            cls._instance._initialize_model()
        return cls._instance

    def _initialize_model(self):
        self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        if RealESRGAN:
            try:
                self._model = RealESRGAN(self._device, scale=settings.MODEL_SCALE)
                if os.path.exists(settings.MODEL_PATH):
                    self._model.load_weights(settings.MODEL_PATH, download=False)
                else:
                    print(f"Warning: Model weights not found at {settings.MODEL_PATH}")
            except Exception as e:
                print(f"Error initializing RealESRGAN: {e}")
                self._model = None
        else:
            self._model = None

    def get_blur_score(self, image_bytes: bytes) -> float:
        """Calculate Laplacian variance to determine image sharpness."""
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.0
        return cv2.Laplacian(img, cv2.CV_64F).var()

    def upscale_image(self, image_bytes: bytes) -> Image.Image:
        """Upscale image using RealESRGAN."""
        torch.cuda.empty_cache()

        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        # Prevent OOM by resizing if too large
        max_size = 1080
        if image.width > max_size or image.height > max_size:
            image.thumbnail((max_size, max_size), Image.LANCZOS)

        if self._model:
            with torch.no_grad():
                sr_image = self._model.predict(image)
        else:
            # Fallback: just resize x4 if model is missing (for testing)
            print("Warning: RealESRGAN model not loaded. Returning resized image.")
            new_size = (
                image.width * settings.MODEL_SCALE,
                image.height * settings.MODEL_SCALE,
            )
            sr_image = image.resize(new_size, Image.BICUBIC)

        torch.cuda.empty_cache()
        return sr_image


image_service = ImageService()

import io
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from app.core.exceptions import AppException

ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/bmp",
}


def validate_image_bytes(data: bytes, max_size_mb: int) -> None:
    if not data:
        raise AppException("Empty image file", status_code=400)
    max_bytes = max_size_mb * 1024 * 1024
    if len(data) > max_bytes:
        raise AppException(f"Image exceeds {max_size_mb} MB limit", status_code=400)
    try:
        Image.open(io.BytesIO(data)).verify()
    except Exception as exc:
        raise AppException("Invalid image file", status_code=400) from exc


def load_image_rgb(data: bytes) -> np.ndarray:
    """Decode uploaded bytes to RGB uint8 array (H, W, 3)."""
    arr = np.frombuffer(data, dtype=np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if bgr is None:
        raise AppException("Could not decode image", status_code=400)
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    return rgb



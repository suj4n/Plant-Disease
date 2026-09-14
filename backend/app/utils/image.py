import io

import cv2
import numpy as np
from PIL import Image

from app.core.exceptions import FileTooLargeError, InvalidImageError

ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/bmp",
}

ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP", "BMP"}

MIN_DIMENSION = 32
MAX_DIMENSION = 8000

# Guard against decompression-bomb uploads (a tiny file that expands to gigapixels).
Image.MAX_IMAGE_PIXELS = MAX_DIMENSION * MAX_DIMENSION


def validate_image_bytes(data: bytes, max_size_mb: int) -> None:
    """Reject anything that is not a plausible, decodable photo.

    The client-declared content type and filename are not trusted: the format and
    dimensions here come from decoding the bytes.
    """
    if not data:
        raise InvalidImageError("The uploaded file is empty.")

    if len(data) > max_size_mb * 1024 * 1024:
        raise FileTooLargeError(f"Image exceeds the {max_size_mb} MB limit.")

    try:
        probe = Image.open(io.BytesIO(data))
        fmt, (width, height) = probe.format, probe.size
        probe.verify()  # consumes the handle, so read format/size first
    except FileTooLargeError:
        raise
    except Exception as exc:
        raise InvalidImageError() from exc

    if fmt not in ALLOWED_FORMATS:
        raise InvalidImageError(f"Unsupported image format: {fmt or 'unknown'}.")

    if width < MIN_DIMENSION or height < MIN_DIMENSION:
        raise InvalidImageError(
            f"Image is too small ({width}x{height}). "
            f"Minimum is {MIN_DIMENSION}x{MIN_DIMENSION} pixels."
        )

    if width > MAX_DIMENSION or height > MAX_DIMENSION:
        raise InvalidImageError(f"Image is too large ({width}x{height} pixels).")


def load_image_rgb(data: bytes) -> np.ndarray:
    """Decode uploaded bytes to an RGB uint8 array (H, W, 3)."""
    arr = np.frombuffer(data, dtype=np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if bgr is None:
        raise InvalidImageError("The image could not be decoded.")
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)

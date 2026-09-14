"""Detect-route tests.

The real 60 MB Keras model is not loaded here: the route logic under test is upload
validation, response shaping and error codes, none of which need real weights.
Inference itself is covered by the class-order / metadata contract tests.
"""

import io

import pytest
from PIL import Image

from app.schemas.detection import PredictionResult
from app.services.disease_detection import TopPrediction, get_detection_service


def _png_bytes(width: int = 256, height: int = 256) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (width, height), (80, 140, 90)).save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture
def stub_model(monkeypatch):
    """Replace inference with a fixed Tomato Early blight prediction."""
    service = get_detection_service()

    prediction = PredictionResult(
        disease="Early blight",
        confidence=0.87,
        plant="Tomato",
        description="A fungal disease.",
        symptoms=["Target-like spots."],
        treatment=["Remove affected leaves."],
        prevention=["Rotate crops."],
        risk_level="medium",
        class_label="Tomato___Early_blight",
    )
    tops = [
        TopPrediction("Tomato___Early_blight", 0.87, "Tomato", "Early blight"),
        TopPrediction("Tomato___Late_blight", 0.08, "Tomato", "Late blight"),
        TopPrediction("Tomato___Target_Spot", 0.03, "Tomato", "Target Spot"),
    ]

    monkeypatch.setattr(service, "predict", lambda rgb, top_k=5: (prediction, tops, 42))
    return service


def test_detect_returns_structured_response(client, stub_model):
    response = client.post(
        "/api/v1/detect",
        files={"file": ("leaf.png", _png_bytes(), "image/png")},
    )
    assert response.status_code == 200
    body = response.json()

    assert body["prediction"]["disease"] == "Early blight"
    assert body["prediction"]["plant"] == "Tomato"
    assert body["prediction"]["risk_level"] == "medium"
    assert body["prediction"]["is_identifiable"] is True

    # The top prediction must not be repeated among the alternatives.
    assert [a["disease"] for a in body["alternatives"]] == ["Late blight", "Target Spot"]

    assert body["information"]["symptoms"] == ["Target-like spots."]
    assert body["metadata"]["processing_time_ms"] == 42
    assert body["metadata"]["model_version"]


def test_legacy_predict_keeps_its_shape(client, stub_model):
    response = client.post(
        "/predict",
        files={"file": ("leaf.png", _png_bytes(), "image/png")},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["disease"] == "Early blight"
    assert body["isHealthy"] is False
    assert isinstance(body["recommendations"], list)
    assert isinstance(body["top_predictions"], list)


def test_detect_rejects_non_image(client):
    response = client.post(
        "/api/v1/detect",
        files={"file": ("notes.txt", b"this is not an image", "image/png")},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_IMAGE"


def test_detect_rejects_tiny_image(client):
    response = client.post(
        "/api/v1/detect",
        files={"file": ("dot.png", _png_bytes(8, 8), "image/png")},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_IMAGE"


def test_detect_rejects_oversized_upload(client):
    oversized = b"\x00" * (11 * 1024 * 1024)
    response = client.post(
        "/api/v1/detect",
        files={"file": ("big.png", oversized, "image/png")},
    )
    assert response.status_code == 413
    assert response.json()["error"]["code"] == "FILE_TOO_LARGE"


def test_error_envelope_carries_code_and_message(client):
    body = client.get("/api/v1/history/999999").json()
    assert body["success"] is False
    assert body["error"]["code"] in {"UNAUTHORIZED", "NOT_FOUND"}
    # Legacy top-level message is retained for older clients.
    assert body["message"] == body["error"]["message"]


def test_anonymous_scan_is_not_written_to_disk(client, stub_model, tmp_path):
    from app.core.config import get_settings

    upload_dir = get_settings().upload_dir
    before = set(upload_dir.glob("*")) if upload_dir.exists() else set()

    client.post(
        "/api/v1/detect",
        files={"file": ("leaf.png", _png_bytes(), "image/png")},
    )

    after = set(upload_dir.glob("*")) if upload_dir.exists() else set()
    assert after == before

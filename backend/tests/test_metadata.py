"""Contract tests between the trained model's classes and the knowledge base.

These make the "do not change class ordering" constraint a test failure rather than
a code-review hope, and stop the knowledge base silently drifting from the classes
the model actually emits.
"""

import json

from app.core.config import get_settings
from app.data.disease_metadata import build_metadata_for_label

EXPECTED_CLASSES = [
    "Apple___Apple_scab",
    "Apple___Black_rot",
    "Apple___Cedar_apple_rust",
    "Apple___healthy",
    "Background_without_leaves",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Strawberry___Leaf_scorch",
    "Strawberry___healthy",
    "Tomato___Bacterial_spot",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy",
]


def _class_names() -> list[str]:
    with get_settings().class_names_path.open(encoding="utf-8") as f:
        return json.load(f)


def test_class_names_and_order_are_unchanged():
    """The model's output indices are positional. Reordering silently mislabels."""
    assert _class_names() == EXPECTED_CLASSES


def test_every_class_has_complete_metadata():
    for label in _class_names():
        meta = build_metadata_for_label(label)
        assert meta["plant"], label
        assert meta["disease"], label
        assert meta["description"], label
        assert meta["risk_level"] in {"low", "medium", "high"}, label
        assert isinstance(meta["symptoms"], list), label
        assert meta["treatment"], label
        assert meta["prevention"], label


def test_diseased_classes_list_symptoms():
    for label in _class_names():
        meta = build_metadata_for_label(label)
        if meta["is_healthy"] or not meta["is_identifiable"]:
            continue
        assert meta["symptoms"], f"{label} has no symptoms listed"


def test_background_class_is_not_identifiable():
    meta = build_metadata_for_label("Background_without_leaves")
    assert meta["is_identifiable"] is False
    assert meta["is_healthy"] is False
    # The raw class label must never reach a user.
    assert "Background_without_leaves" not in meta["description"]
    assert "Background" not in meta["disease"]


def test_healthy_classes_are_flagged_healthy_and_low_risk():
    for label in _class_names():
        if not label.endswith("___healthy"):
            continue
        meta = build_metadata_for_label(label)
        assert meta["is_healthy"] is True, label
        assert meta["risk_level"] == "low", label
        assert meta["disease"].startswith("Healthy "), label

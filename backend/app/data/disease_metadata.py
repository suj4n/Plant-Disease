"""Static knowledge base keyed by model class labels (Plant___Disease format)."""

from __future__ import annotations

GENERIC_TREATMENT = [
    "Remove and destroy severely infected leaves.",
    "Improve air circulation around plants.",
    "Avoid overhead watering; water at the base in the morning.",
    "Apply an appropriate fungicide or bactericide per label directions.",
]

GENERIC_PREVENTION = [
    "Use disease-resistant cultivars when available.",
    "Rotate crops and avoid planting the same family in the same spot yearly.",
    "Sanitize tools between plants.",
    "Monitor plants weekly for early symptoms.",
]

PLANT_SCIENTIFIC: dict[str, str] = {
    "Apple": "Malus domestica",
    "Potato": "Solanum tuberosum",
    "Strawberry": "Fragaria × ananassa",
    "Tomato": "Solanum lycopersicum",
}

PLANT_CARE: dict[str, str] = {
    "Apple": "Full sun, well-drained soil, annual pruning, consistent moisture during fruit set.",
    "Potato": "Cool seasons, hilling soil around stems, consistent moisture, avoid waterlogged beds.",
    "Strawberry": "Full sun, acidic well-drained soil, mulch to reduce fruit rot.",
    "Tomato": "6–8 hours sun, support with stakes/cages, even watering, fertilize after first fruit.",
}


def _humanize(label: str) -> tuple[str, str, bool]:
    """Parse 'Tomato___Early_blight' -> plant, disease, is_healthy"""
    
    if label == "Background_without_leaves":
        return "Unknown", "No leaf detected", False

    if "___" not in label:
        return "Unknown", label.replace("_", " "), False

    plant, disease = label.split("___", 1)

    if disease.lower() == "healthy":
        return plant, "Healthy", True

    return plant, disease.replace("_", " "), False


def build_metadata_for_label(class_label: str) -> dict:
    plant, disease, is_healthy = _humanize(class_label)

    # ---------------- HEALTHY CASE ----------------
    if is_healthy:
        return {
            "plant": plant,
            "disease": f"Healthy {plant}",
            "scientific_name": PLANT_SCIENTIFIC.get(plant, ""),
            "care": PLANT_CARE.get(plant, ""),
            "description": f"No disease symptoms detected. The {plant.lower()} leaf appears healthy.",
            "treatment": ["No treatment required.", "Continue regular watering and monitoring."],
            "prevention": [
                "Maintain balanced fertilization.",
                "Ensure adequate spacing and sunlight.",
                "Inspect regularly for early signs of stress or pests.",
            ],
            "is_healthy": True,
        }

    # ---------------- NO LEAF CASE ----------------
    if class_label == "Background_without_leaves":
        return {
            "plant": "Unknown",
            "disease": "No leaf detected",
            "scientific_name": "",
            "care": "",
            "description": "No clear plant leaf detected. Please capture a single leaf with good lighting and plain background.",
            "treatment": ["Retake the image focusing on one clear leaf."],
            "prevention": ["Center the leaf and avoid cluttered backgrounds."],
            "is_healthy": False,
        }

    # ---------------- DISEASE DESCRIPTIONS ----------------
    descriptions: dict[str, str] = {
        # Apple
        "Apple scab": "Fungal disease causing dark olive lesions on leaves and fruit.",
        "Black rot": "Fungal infection causing leaf spots, cankers, and fruit rot.",
        "Cedar apple rust": "Rust fungus causing yellow-orange leaf spots and premature leaf drop.",

        # Potato
        "Early blight": "Fungal disease causing concentric ring spots on older leaves.",
        "Late blight": "Severe disease causing rapid leaf collapse in wet, cool conditions.",

        # Strawberry
        "Leaf scorch": "Fungal disease causing purple-brown leaf lesions and drying edges.",

        # Tomato (bacterial/fungal/viral/pests)
        "Bacterial spot": "Bacterial infection causing dark lesions on leaves and fruit.",
        "Leaf Mold": "Fungal disease causing yellow upper leaf spots and gray mold underneath.",
        "Septoria leaf spot": "Fungal disease causing circular spots with gray centers.",
        "Spider mites Two-spotted spider mite": "Pest infestation causing speckled, bronzed leaves and webbing.",
        "Target Spot": "Fungal disease causing concentric ring lesions on leaves.",
        "Tomato Yellow Leaf Curl Virus": "Viral disease causing curling, yellowing, and stunted growth.",
        "Tomato mosaic virus": "Viral disease causing mottled mosaic patterns and leaf distortion.",
    }

    desc = descriptions.get(
        disease,
        f"Detected {disease.lower()} on {plant.lower()}. Consult agricultural guidance for confirmation.",
    )

    return {
        "plant": plant,
        "disease": disease,
        "scientific_name": PLANT_SCIENTIFIC.get(plant, ""),
        "care": PLANT_CARE.get(plant, ""),
        "description": desc,
        "treatment": list(GENERIC_TREATMENT),
        "prevention": list(GENERIC_PREVENTION),
        "is_healthy": False,
    }
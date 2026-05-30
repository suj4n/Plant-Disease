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
    """Parse 'Tomato___Early_blight' -> plant, disease display name, is_healthy."""
    if "___" not in label:
        return "Unknown", label.replace("_", " "), False
    plant, rest = label.split("___", 1)
    if rest.lower() == "healthy":
        return plant, "Healthy", True
    if label == "Background_without_leaves":
        return "Unknown", "No leaf detected", False
    disease = rest.replace("_", " ")
    return plant, disease, False


def build_metadata_for_label(class_label: str) -> dict:
    plant, disease, is_healthy = _humanize(class_label)

    if is_healthy:
        return {
            "plant": plant,
            "disease": f"Healthy {plant}",
            "description": f"No disease symptoms detected. The {plant.lower()} foliage appears healthy.",
            "treatment": ["No treatment required.", "Continue regular watering and monitoring."],
            "prevention": [
                "Maintain balanced fertilization.",
                "Ensure adequate spacing and sunlight.",
                "Inspect regularly for early signs of stress or pests.",
            ],
            "is_healthy": True,
        }

    if class_label == "Background_without_leaves":
        return {
            "plant": "Unknown",
            "disease": "No leaf detected",
            "description": "The image does not appear to contain a clear plant leaf. Please photograph a single leaf with good lighting.",
            "treatment": ["Retake the photo focusing on one leaf against a plain background."],
            "prevention": ["Center the leaf in frame and avoid busy backgrounds."],
            "is_healthy": False,
        }

    descriptions: dict[str, str] = {
        "Apple scab": "Fungal disease causing olive-green to dark brown spots on leaves and fruit.",
        "Black rot": "Fungal infection with frogeye leaf spots and fruit rot in warm, humid weather.",
        "Cedar apple rust": "Rust fungus producing yellow-orange leaf spots; requires juniper hosts to complete its cycle.",
        "Early blight": "Common fungal blight with concentric 'target' rings on older leaves.",
        "Late blight": "Destructive oomycete disease spreading rapidly in cool, wet conditions.",
        "Leaf scorch": "Physiological or pathogen-related scorching of leaf margins on strawberry.",
        "Bacterial spot": "Bacterial disease causing small dark lesions on leaves and fruit.",
        "Leaf Mold": "Fungal disease with yellow patches on upper leaf surfaces and mold underneath.",
        "Septoria leaf spot": "Fungal spotting with gray centers and dark borders on tomato leaves.",
        "Spider mites Two-spotted spider mite": "Tiny pests causing stippling, bronzing, and webbing on leaves.",
        "Target Spot": "Fungal leaf spots with concentric rings, often on lower canopy leaves.",
        "Tomato Yellow Leaf Curl Virus": "Viral disease causing upward curling, yellowing, and stunted growth.",
        "Tomato mosaic virus": "Viral disease with mosaic patterns, leaf distortion, and reduced vigor.",
    }

    desc = descriptions.get(
        disease,
        f"Detected {disease.lower()} on {plant.lower()}. Consult local extension guidance for confirmation.",
    )

    return {
        "plant": plant,
        "disease": disease,
        "description": desc,
        "treatment": list(GENERIC_TREATMENT),
        "prevention": list(GENERIC_PREVENTION),
        "is_healthy": False,
    }

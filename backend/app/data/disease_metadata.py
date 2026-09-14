"""Static knowledge base keyed by model class labels (Plant___Disease format).

Risk level is an *agronomic severity* judgement per disease. It is deliberately
independent of model confidence: confidence says how sure the model is, risk says
how much damage the disease does if it is really there. Conflating the two produces
nonsense like "95% confident it is healthy" rendered in alarm red.
"""

from __future__ import annotations

from typing import Literal

RiskLevel = Literal["low", "medium", "high"]

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

GENERIC_SYMPTOMS = [
    "Discoloured or spotted leaves.",
    "Lesions that spread over time.",
    "Premature leaf drop or wilting.",
]

PLANT_SCIENTIFIC: dict[str, str] = {
    "Apple": "Malus domestica",
    "Potato": "Solanum tuberosum",
    "Strawberry": "Fragaria x ananassa",
    "Tomato": "Solanum lycopersicum",
}

PLANT_CARE: dict[str, str] = {
    "Apple": "Full sun, well-drained soil, annual pruning, consistent moisture during fruit set.",
    "Potato": "Cool seasons, hilling soil around stems, consistent moisture, avoid waterlogged beds.",
    "Strawberry": "Full sun, acidic well-drained soil, mulch to reduce fruit rot.",
    "Tomato": "6-8 hours sun, support with stakes/cages, even watering, fertilize after first fruit.",
}


class DiseaseInfo:
    """One knowledge-base entry. Keyed by the humanised disease name."""

    __slots__ = ("description", "symptoms", "treatment", "prevention", "risk_level")

    def __init__(
        self,
        description: str,
        symptoms: list[str],
        risk_level: RiskLevel,
        treatment: list[str] | None = None,
        prevention: list[str] | None = None,
    ) -> None:
        self.description = description
        self.symptoms = symptoms
        self.risk_level = risk_level
        self.treatment = treatment or list(GENERIC_TREATMENT)
        self.prevention = prevention or list(GENERIC_PREVENTION)


DISEASES: dict[str, DiseaseInfo] = {
    # ---------------- Apple ----------------
    "Apple scab": DiseaseInfo(
        "A fungal disease (Venturia inaequalis) that produces dark, velvety lesions "
        "on leaves and fruit and causes early leaf drop in wet springs.",
        [
            "Olive-green to dark brown velvety spots on leaves.",
            "Spots with feathered, indistinct edges.",
            "Scabby, cracked lesions on fruit.",
            "Early yellowing and leaf drop.",
        ],
        "medium",
        treatment=[
            "Remove and destroy fallen leaves to break the infection cycle.",
            "Prune to open the canopy and speed drying after rain.",
            "Apply a scab-labelled fungicide from green tip through petal fall.",
        ],
        prevention=[
            "Plant scab-resistant apple varieties.",
            "Rake and remove leaf litter every autumn.",
            "Avoid overhead irrigation during leaf-out.",
        ],
    ),
    "Black rot": DiseaseInfo(
        "A fungal infection (Botryosphaeria obtusa) causing leaf spots, branch cankers "
        "and a firm, dark rot of the fruit.",
        [
            "Purple-edged circular leaf spots ('frogeye' spots).",
            "Sunken cankers on branches.",
            "Firm black rot on fruit, often with concentric rings.",
            "Mummified fruit hanging on the tree.",
        ],
        "high",
        treatment=[
            "Prune out and burn cankered wood well below the visible lesion.",
            "Remove all mummified fruit from the tree and ground.",
            "Apply a labelled fungicide during the growing season.",
        ],
    ),
    "Cedar apple rust": DiseaseInfo(
        "A rust fungus (Gymnosporangium juniperi-virginianae) that alternates between "
        "junipers and apples, producing bright yellow-orange leaf spots.",
        [
            "Bright yellow-orange spots on the upper leaf surface.",
            "Small black dots within the spots.",
            "Tube-like growths on the leaf underside.",
            "Premature leaf drop in heavy infections.",
        ],
        "low",
        prevention=[
            "Remove nearby juniper or cedar hosts where practical.",
            "Plant rust-resistant apple varieties.",
            "Apply a preventative fungicide at pink bud if rust is common locally.",
        ],
    ),
    # ---------------- Potato / Tomato shared ----------------
    "Early blight": DiseaseInfo(
        "A fungal disease (Alternaria solani) that starts on older, lower leaves and "
        "produces spots with characteristic concentric rings.",
        [
            "Dark brown spots with concentric rings, like a target.",
            "Yellow halo around each spot.",
            "Lower, older leaves affected first.",
            "Leaves yellow, die and drop upwards through the plant.",
        ],
        "medium",
        treatment=[
            "Remove affected lower leaves and dispose of them away from the plot.",
            "Mulch to stop soil splashing spores onto leaves.",
            "Apply a chlorothalonil or copper-based fungicide per label directions.",
        ],
        prevention=[
            "Rotate out of the nightshade family for at least two years.",
            "Stake or cage plants to keep foliage off the soil.",
            "Water at the base, never over the canopy.",
        ],
    ),
    "Late blight": DiseaseInfo(
        "A water-mould disease (Phytophthora infestans) that can destroy a crop within "
        "days in cool, wet weather. This is the disease behind historic potato famines.",
        [
            "Large, irregular water-soaked patches on leaves.",
            "White fuzzy growth on the leaf underside in humid conditions.",
            "Rapid browning and collapse of foliage.",
            "Firm brown rot on tubers or fruit.",
        ],
        "high",
        treatment=[
            "Act immediately - this disease spreads extremely fast.",
            "Remove and destroy infected plants; do not compost them.",
            "Apply a late-blight-labelled fungicide to remaining healthy plants.",
            "Harvest tubers only in dry conditions and cure them before storage.",
        ],
        prevention=[
            "Plant certified disease-free seed potatoes.",
            "Choose blight-resistant varieties.",
            "Space plants generously for airflow and destroy volunteer plants.",
        ],
    ),
    # ---------------- Strawberry ----------------
    "Leaf scorch": DiseaseInfo(
        "A fungal disease (Diplocarpon earlianum) producing dark purple blotches that "
        "merge until the leaf looks burnt.",
        [
            "Small dark purple spots scattered across the leaf.",
            "Spots merging into large blotches.",
            "Leaf margins drying and curling, looking scorched.",
            "Reduced runner and fruit production.",
        ],
        "medium",
        prevention=[
            "Renovate beds after harvest and thin crowded plantings.",
            "Remove old infected foliage at the end of the season.",
            "Use drip irrigation instead of overhead watering.",
        ],
    ),
    # ---------------- Tomato ----------------
    "Bacterial spot": DiseaseInfo(
        "A bacterial infection (Xanthomonas spp.) producing small dark lesions on "
        "leaves, stems and fruit. It spreads readily in warm, wet weather.",
        [
            "Small dark brown water-soaked spots on leaves.",
            "Spots with a yellow halo that may drop out, giving a shot-hole look.",
            "Raised scabby spots on fruit.",
            "Leaf yellowing and drop in severe cases.",
        ],
        "high",
        treatment=[
            "Remove and destroy infected plants; bacteria cannot be cured in place.",
            "Apply a copper-based bactericide to protect remaining plants.",
            "Avoid working among plants while the foliage is wet.",
        ],
        prevention=[
            "Use certified disease-free seed and transplants.",
            "Rotate away from tomatoes and peppers for two years.",
            "Sanitize stakes, cages and tools between seasons.",
        ],
    ),
    "Leaf Mold": DiseaseInfo(
        "A fungal disease (Passalora fulva) common in humid, poorly ventilated growing "
        "spaces such as greenhouses and polytunnels.",
        [
            "Pale yellow-green patches on the upper leaf surface.",
            "Olive-green to grey velvety mould on the underside.",
            "Leaves curling, browning and dropping.",
            "Mostly older, lower leaves affected first.",
        ],
        "medium",
        treatment=[
            "Increase ventilation and lower humidity immediately.",
            "Remove affected leaves and improve plant spacing.",
            "Apply a labelled fungicide if the spread continues.",
        ],
    ),
    "Septoria leaf spot": DiseaseInfo(
        "A fungal disease (Septoria lycopersici) producing many small circular spots "
        "with pale centres, usually starting after the first fruit sets.",
        [
            "Numerous small circular spots with grey or tan centres.",
            "Dark brown margins around each spot.",
            "Tiny black specks visible in the spot centres.",
            "Lower leaves yellow and drop first.",
        ],
        "medium",
        prevention=[
            "Mulch heavily to block soil splash.",
            "Remove lower leaves touching the ground.",
            "Rotate crops and clear all plant debris at season end.",
        ],
    ),
    "Spider mites Two-spotted spider mite": DiseaseInfo(
        "A pest infestation (Tetranychus urticae) rather than a disease. Mites feed on "
        "the leaf underside and thrive in hot, dry, dusty conditions.",
        [
            "Fine pale stippling or speckling on leaves.",
            "Leaves turning bronze or dull grey.",
            "Fine webbing on the leaf underside and between stems.",
            "Tiny moving dots visible on the underside with a hand lens.",
        ],
        "medium",
        treatment=[
            "Spray the leaf undersides forcefully with water to dislodge mites.",
            "Apply insecticidal soap or horticultural oil, repeating weekly.",
            "Introduce predatory mites where biological control is practical.",
        ],
        prevention=[
            "Keep plants well watered - drought stress invites mites.",
            "Avoid broad-spectrum insecticides that kill natural predators.",
            "Remove dusty weeds around the planting.",
        ],
    ),
    "Target Spot": DiseaseInfo(
        "A fungal disease (Corynespora cassiicola) producing concentric-ringed lesions "
        "on leaves, stems and fruit in warm, humid conditions.",
        [
            "Small brown spots that enlarge into rings resembling a target.",
            "Lesions on stems and fruit as well as leaves.",
            "Defoliation starting from the lower canopy.",
            "Sunken circular lesions on fruit.",
        ],
        "medium",
    ),
    "Tomato Yellow Leaf Curl Virus": DiseaseInfo(
        "A viral disease spread by whiteflies. There is no cure once a plant is "
        "infected; management targets the whitefly vector.",
        [
            "Leaves curling upward with yellow margins.",
            "Severely stunted, bushy growth.",
            "Flowers dropping without setting fruit.",
            "Sharp reduction or total loss of yield.",
        ],
        "high",
        treatment=[
            "Remove and destroy infected plants - the virus cannot be cured.",
            "Control whiteflies with yellow sticky traps and insecticidal soap.",
            "Bag plants before removal so whiteflies do not disperse.",
        ],
        prevention=[
            "Plant TYLCV-resistant varieties.",
            "Use fine insect netting or reflective mulch against whiteflies.",
            "Inspect transplants for whiteflies before planting.",
        ],
    ),
    "Tomato mosaic virus": DiseaseInfo(
        "A highly persistent virus spread mainly by handling and contaminated tools. "
        "It survives in plant debris and on surfaces for a long time.",
        [
            "Mottled light and dark green mosaic pattern on leaves.",
            "Distorted, narrow or fern-like leaves.",
            "Stunted growth and uneven fruit ripening.",
            "Internal browning of fruit.",
        ],
        "high",
        treatment=[
            "Remove and destroy infected plants - there is no cure.",
            "Wash hands and disinfect all tools before touching healthy plants.",
            "Do not use tobacco products near tomato plants.",
        ],
        prevention=[
            "Use certified virus-free seed and resistant varieties.",
            "Disinfect stakes, cages and tools between seasons.",
            "Clear all plant debris thoroughly at the end of the season.",
        ],
    ),
}


def _humanize(label: str) -> tuple[str, str, bool]:
    """Parse 'Tomato___Early_blight' -> (plant, disease, is_healthy)."""
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

    # ---------------- NO LEAF ----------------
    # Checked before the healthy branch: the client renders a dedicated recovery
    # state for this and must never see the raw class label.
    if class_label == "Background_without_leaves":
        return {
            "plant": "Unknown",
            "disease": "No leaf detected",
            "scientific_name": "",
            "care": "",
            "description": (
                "No clear plant leaf was detected in this photo. Capture a single "
                "leaf with good lighting against a plain background."
            ),
            "symptoms": [],
            "treatment": ["Retake the photo focusing on one clear leaf."],
            "prevention": ["Center the leaf and avoid cluttered backgrounds."],
            "is_healthy": False,
            "is_identifiable": False,
            "risk_level": "low",
        }

    # ---------------- HEALTHY ----------------
    if is_healthy:
        return {
            "plant": plant,
            "disease": f"Healthy {plant}",
            "scientific_name": PLANT_SCIENTIFIC.get(plant, ""),
            "care": PLANT_CARE.get(plant, ""),
            "description": (
                f"No disease symptoms were detected. This {plant.lower()} leaf "
                "appears healthy."
            ),
            "symptoms": [],
            "treatment": ["No treatment required.", "Continue regular watering and monitoring."],
            "prevention": [
                "Maintain balanced fertilization.",
                "Ensure adequate spacing and sunlight.",
                "Inspect regularly for early signs of stress or pests.",
            ],
            "is_healthy": True,
            "is_identifiable": True,
            "risk_level": "low",
        }

    # ---------------- DISEASE ----------------
    info = DISEASES.get(disease)
    if info is None:
        return {
            "plant": plant,
            "disease": disease,
            "scientific_name": PLANT_SCIENTIFIC.get(plant, ""),
            "care": PLANT_CARE.get(plant, ""),
            "description": (
                f"Detected {disease.lower()} on {plant.lower()}. Consult local "
                "agricultural guidance to confirm."
            ),
            "symptoms": list(GENERIC_SYMPTOMS),
            "treatment": list(GENERIC_TREATMENT),
            "prevention": list(GENERIC_PREVENTION),
            "is_healthy": False,
            "is_identifiable": True,
            "risk_level": "medium",
        }

    return {
        "plant": plant,
        "disease": disease,
        "scientific_name": PLANT_SCIENTIFIC.get(plant, ""),
        "care": PLANT_CARE.get(plant, ""),
        "description": info.description,
        "symptoms": list(info.symptoms),
        "treatment": list(info.treatment),
        "prevention": list(info.prevention),
        "is_healthy": False,
        "is_identifiable": True,
        "risk_level": info.risk_level,
    }

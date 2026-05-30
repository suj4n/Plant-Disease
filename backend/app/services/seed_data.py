import json
import logging

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.data.disease_metadata import PLANT_CARE, PLANT_SCIENTIFIC, build_metadata_for_label
from app.models.disease import Disease
from app.models.plant import Plant

logger = logging.getLogger(__name__)


def seed_plants_and_diseases(db: Session) -> None:
    settings = get_settings()
    if db.query(Disease).count() >= 10:
        return

    if not settings.class_names_path.exists():
        logger.warning("class_names.json missing; skipping seed")
        return

    with settings.class_names_path.open(encoding="utf-8") as f:
        class_names: list[str] = json.load(f)

    plants_seen: set[str] = set()
    for label in class_names:
        meta = build_metadata_for_label(label)
        plant_name = meta["plant"]
        if plant_name not in plants_seen and plant_name != "Unknown":
            plants_seen.add(plant_name)
            existing = db.query(Plant).filter(Plant.name == plant_name).first()
            if not existing:
                db.add(
                    Plant(
                        name=plant_name,
                        scientific_name=PLANT_SCIENTIFIC.get(plant_name),
                        description=f"Common garden crop: {plant_name}.",
                        care_tips=PLANT_CARE.get(plant_name),
                    )
                )

        if label == "Background_without_leaves":
            continue
        # Unique per plant+disease combo (Early blight exists on Potato and Tomato)
        disease_name = label.replace("___", " — ").replace("_", " ")
        existing_d = db.query(Disease).filter(Disease.name == disease_name).first()
        if not existing_d:
            db.add(
                Disease(
                    name=disease_name,
                    description=meta["description"],
                    symptoms=meta["description"],
                    causes="Environmental stress, pathogens, or pests depending on condition.",
                    treatment="\n".join(meta["treatment"]),
                    prevention="\n".join(meta["prevention"]),
                )
            )

    db.commit()
    logger.info("Seeded plants and diseases knowledge base")

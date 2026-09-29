"""Export the trained model and disease knowledge base for on-device inference.

Run from the repo root with the backend venv (it needs TensorFlow and the
backend's disease metadata):

    backend/.venv/Scripts/python.exe scripts/export_tflite.py

Writes to flutter/assets/models/:
  plant_model.tflite   float32, same maths as model/plant_best_model.keras
  disease_info.json    class order + everything the result screen shows

Re-run after every retrain. The model takes raw RGB 0-255 at 224x224;
preprocessing is a layer inside it.
"""
import json
import pathlib
import sys

import cv2
import numpy as np
import tensorflow as tf

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "flutter" / "assets" / "models"
sys.path.insert(0, str(ROOT / "backend"))

from app.core.config import get_settings  # noqa: E402
from app.data.disease_metadata import build_metadata_for_label  # noqa: E402

settings = get_settings()
class_names = json.loads(settings.class_names_path.read_text(encoding="utf-8"))

trained = tf.keras.models.load_model(settings.model_path, compile=False)
# Trained under mixed_float16, which TFLite builtins reject. Rebuild the same
# graph in float32 and copy the weights across.
config = json.loads(json.dumps(trained.get_config()).replace('"mixed_float16"', '"float32"'))
model = tf.keras.Model.from_config(config)
model.set_weights(trained.get_weights())

tflite = tf.lite.TFLiteConverter.from_keras_model(model).convert()
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "plant_model.tflite").write_bytes(tflite)

fields = ("plant", "disease", "description", "symptoms", "treatment", "prevention",
          "is_healthy", "is_identifiable", "risk_level", "scientific_name")
info = {
    "model_version": f"{settings.model_version}-tflite-fp32",
    "input_size": settings.model_input_size,
    "class_names": class_names,
    "classes": {label: {k: build_metadata_for_label(label).get(k) for k in fields}
                for label in class_names},
}
(OUT / "disease_info.json").write_text(json.dumps(info, indent=1, ensure_ascii=False),
                                       encoding="utf-8")

# Check: the exported model must agree with the Keras model it came from.
size = settings.model_input_size
samples = sorted((ROOT / "flutter" / "assets" / "images").glob("*.jpg"))
batch = np.stack([cv2.resize(cv2.cvtColor(cv2.imread(str(p)), cv2.COLOR_BGR2RGB),
                             (size, size), interpolation=cv2.INTER_LINEAR)
                  for p in samples]).astype(np.float32)
expected = model.predict(batch, verbose=0)
interp = tf.lite.Interpreter(model_content=tflite)
interp.allocate_tensors()
inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
for i in range(len(batch)):
    interp.set_tensor(inp["index"], batch[i:i + 1])
    interp.invoke()
    got = interp.get_tensor(out["index"])[0]
    assert got.argmax() == expected[i].argmax(), f"top-1 mismatch on {samples[i].name}"
    assert np.abs(got - expected[i]).max() < 1e-4, f"probability drift on {samples[i].name}"

print(f"plant_model.tflite  {len(tflite) / 1e6:.1f} MB  "
      f"input {inp['shape'].tolist()} {inp['dtype'].__name__}")
print(f"disease_info.json   {len(class_names)} classes, {info['model_version']}")
print(f"verified against Keras on {len(batch)} images: identical top-1, max drift < 1e-4")

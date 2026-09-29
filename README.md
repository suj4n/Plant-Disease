# PlantDoc — Plant Disease Detection

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow_Lite-on--device-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi)](https://fastapi.tiangolo.com)

Identify crop diseases from a single leaf photo — **on the phone, with no internet
connection.** Built for growers in the field, with treatment and prevention guidance
for every diagnosis.

## Download

| APK | For |
|---|---|
| **[PlantDoc-arm64.apk](https://github.com/suj4n/Plant-Disease/releases/latest/download/PlantDoc-arm64.apk)** (~39 MB) | Almost every Android phone from the last ~7 years |
| [PlantDoc-universal.apk](https://github.com/suj4n/Plant-Disease/releases/latest/download/PlantDoc-universal.apk) (~86 MB) | Any device — use this if the one above won't install |

Android will ask you to allow installing from this source the first time.
All versions: [Releases](https://github.com/suj4n/Plant-Disease/releases).

## Features

- **Offline diagnosis** — the model runs on the phone; photos never leave it
- **20 classes across 4 crops** — Apple, Potato, Strawberry, Tomato (diseases + healthy), plus a "no leaf" class that rejects non-leaf photos
- **Guidance** — symptoms, treatment and prevention for each disease, with a risk level
- **Scan history** — saved locally, synced to the cloud when signed in
- **Plant tracker** — log plantings and get a reminder to re-scan every 14 days

## Model

MobileNetV2 fine-tuned on the PlantVillage dataset (26,191 images), exported to
TensorFlow Lite (float32, 12 MB).

| Metric (held-out test set, 2,620 images) | Score |
|---|---|
| Accuracy | **99.39%** |
| Macro F1 | 0.9945 |
| Macro AUC | 0.9998 |
| Errors | 16 |

![Training history](Resources/__results___images/fig03_training_history.png)

Train and validation accuracy stay within 0.7 points and validation loss falls to
the last epoch, so the model is not overfitting. Full evaluation figures are in
[`Resources/__results___images/`](Resources/__results___images/).

**Limitation:** PlantVillage images are single leaves on plain backgrounds. Expect
lower accuracy on photos taken in the field with soil, other foliage or strong shadows.

## How it works

```
Photo ─► resize 224×224 ─► TFLite model (on phone) ─► disease + guidance
                                   │
                                   └─ if on-device inference fails ─► FastAPI server
```

- **App** (`flutter/`) — Flutter, Supabase auth, TFLite inference, SQLite + local notifications
- **Server** (`backend/`) — FastAPI + TensorFlow, the same model; used as a fallback
- **Model** (`model/`) — trained Keras model; preprocessing is built into the model

## Run it yourself

**Backend**

```bash
cd backend
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt   # macOS/Linux: .venv/bin/pip
cp .env.example .env
.venv/Scripts/python -m uvicorn app.main:app --port 8000
```

**App** — set `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `API_BASE_URL` in `flutter/.env`, then:

```bash
cd flutter
flutter pub get
flutter run
```

**Build the APKs**

```bash
cd flutter
flutter build apk --release --split-per-abi   # per-device APKs
flutter build apk --release                   # universal APK
```

**After retraining** — copy the new `plant_best_model.keras` to `model/`, then
regenerate the phone model and knowledge base (this also checks the phone model
against the Keras one):

```bash
backend/.venv/Scripts/python scripts/export_tflite.py
```

Detailed setup, USB/Wi-Fi debugging and troubleshooting: [running_Instruction.md](running_Instruction.md).

## Tests

```bash
cd backend && .venv/Scripts/python -m pytest -q
cd flutter && flutter test
```

## Project structure

```
flutter/     Android app (Flutter)
backend/     FastAPI server
model/       Trained Keras model
Resources/   Class labels, training logs, evaluation figures
scripts/     Setup, dev and model-export scripts
```

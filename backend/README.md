# PlantDoc FastAPI Backend

Production-ready API for the PlantDoc Flutter app. Runs **Keras MobileNetV2** inference on `../model/plant_best_model.keras` (224×224 RGB input, 20 classes from `../Resources/class_names.json`).

## Stack

- FastAPI, Uvicorn, Pydantic v2, SQLAlchemy, SQLite, Alembic, JWT

## Quick start (local + Android USB)

```bash
cd backend
py -3.11 -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS/Linux

pip install -r requirements.txt
copy .env.example .env          # edit SECRET_KEY for production
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Swagger: http://127.0.0.1:8000/docs  
- Health: http://127.0.0.1:8000/health  

## Connect Flutter on a physical Android device

### Option A — Same Wi‑Fi (LAN IP)

1. Find your PC IP:
   - Windows: `ipconfig` → IPv4 (e.g. `192.168.1.42`)
   - macOS/Linux: `ifconfig` or `ip addr`
2. Start the API with `--host 0.0.0.0`.
3. In Flutter (`lib/core/services/api_service.dart`):

```dart
static const baseUrl = 'http://192.168.1.42:8000';
```

4. Add to `android/app/src/main/AndroidManifest.xml` (before `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

5. For HTTP (not HTTPS) on Android 9+, add `android:usesCleartextTraffic="true"` on `<application>` or a network security config.

### Option B — USB debugging (`adb reverse`)

```bash
adb reverse tcp:8000 tcp:8000
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Flutter:

```dart
static const baseUrl = 'http://127.0.0.1:8000';
```

## API overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Health check |
| POST | `/predict` | Optional | **Legacy** — Flutter-compatible scan |
| POST | `/api/v1/detect` | Optional | Multipart scan + structured prediction |
| GET | `/api/v1/history` | Yes | User scan history |
| GET | `/api/v1/history/{id}` | Yes | Scan detail |
| DELETE | `/api/v1/history/{id}` | Yes | Delete scan |
| POST | `/api/v1/auth/register` | No | Register |
| POST | `/api/v1/auth/login` | No | Login |
| POST | `/api/v1/auth/refresh` | No | Refresh access token |
| GET | `/api/v1/auth/me` | Yes | Profile |
| GET | `/api/v1/plants` | No | Plant catalog |
| GET | `/api/v1/diseases` | No | Disease knowledge base |
| POST/GET/DELETE | `/api/v1/favorites` | Yes | Favorites |

### Legacy predict (Flutter)

```bash
curl -X POST "http://127.0.0.1:8000/predict?top_k=5" -F "file=@leaf.jpg"
```

Response fields used by the app: `disease`, `confidence`, `isHealthy`, `recommendations`.

### Modern detect

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/detect" -F "file=@leaf.jpg" \
  -H "Authorization: Bearer <access_token>"
```

## Docker

From `backend/`:

```bash
docker compose up --build
```

Mounts `../model` and class names into the container.

## Tests

```bash
cd backend
pytest -q
```

## Model details

| Property | Value |
|----------|--------|
| File | `model/plant_best_model.keras` |
| Architecture | MobileNetV2 (`plant_mobilenetv2`) |
| Input | 224 × 224 × 3 float32 |
| Preprocessing | `tensorflow.keras.applications.mobilenet_v2.preprocess_input` |
| Output | 20-class softmax |
| Labels | `Resources/class_names.json` |

## Project layout

```text
backend/
├── app/
│   ├── api/routes/          # HTTP endpoints
│   ├── api/dependencies/    # Auth & DB deps
│   ├── core/                # Config, security, exceptions
│   ├── services/            # ML, auth, seed data
│   ├── models/              # SQLAlchemy ORM
│   ├── schemas/             # Pydantic v2
│   ├── database/
│   ├── utils/
│   └── main.py
├── alembic/
├── uploads/
├── tests/
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

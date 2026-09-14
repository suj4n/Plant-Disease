# PlantDoc API

FastAPI service that runs the MobileNetV2 plant-disease classifier and backs the
PlantDoc mobile app.

---

## Requirements

- Python 3.11 (3.13 works; TensorFlow wheels must be available for your platform)
- The trained model at `../model/plant_best_model.keras` (~60 MB)
- The class list at `../Resources/class_names.json` (20 labels, order significant)

## Install

```bash
cd backend
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
```

## Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Interactive docs: <http://localhost:8000/docs>. From the repo root, the Windows
helper script does the same thing: `.\scripts\backend.ps1`.

The model is loaded once during application startup (`lifespan` in
`app/main.py`), not per request. The first request after boot is therefore fast,
but boot itself takes a few seconds while TensorFlow loads.

## Environment variables

Copy `.env.example` to `.env`. Everything has a working development default, so
an empty `.env` still runs locally.

| Variable | Default | Notes |
|---|---|---|
| `DEBUG` | `true` | **Set `false` in production.** |
| `SECRET_KEY` | placeholder | JWT signing key. With `DEBUG=false` the app **refuses to start** while this is still the placeholder. Generate with `openssl rand -hex 32`. |
| `DATABASE_URL` | `sqlite:///backend/plantdoc.db` | Any SQLAlchemy URL. |
| `CORS_ORIGINS` | local dev hosts | JSON list of explicit origins in production. Credentials are only enabled when this is not `["*"]` — browsers reject wildcard + credentials. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | |
| `MODEL_PATH` | `../model/plant_best_model.keras` | |
| `CLASS_NAMES_PATH` | `../Resources/class_names.json` | |
| `MAX_UPLOAD_SIZE_MB` | `10` | Must match the Flutter client's limit. |
| `MODEL_VERSION` | `mobilenetv2-20c-v1` | Reported in `/health` and detection metadata. |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | unset | Optional. **Never** ship the service-role key to a client. |

## Database

SQLAlchemy models live in `app/models/`; migrations in `alembic/versions/`.

```bash
alembic upgrade head                        # apply
alembic revision --autogenerate -m "..."    # after changing a model
```

Tables: `users`, `detections`, `plants`, `diseases`, `favorites`.

> `app/main.py` also calls `Base.metadata.create_all()` at startup for a
> zero-setup local run. In production, run `alembic upgrade head` and treat
> Alembic as the source of truth for schema.

## Authentication

The API issues its own HS256 JWTs via `/api/v1/auth/*` (`access` + `refresh`,
distinguished by a `type` claim). Send `Authorization: Bearer <access_token>`.

> **Known gap.** The Flutter app authenticates against Supabase and sends its
> *Supabase* token. That token cannot validate against this service's own
> `SECRET_KEY`, so the mobile client is always treated as anonymous here.
> Detection still works — `/detect` and `/predict` accept anonymous requests —
> but per-user history in this database is only reachable by a client that logs
> in through `/api/v1/auth/login`. See `docs/BACKEND_REWORK_PLAN.md`
> ("Authentication") for why this was documented rather than bridged.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health`, `/api/v1/health` | — | API, model and database readiness |
| POST | `/api/v1/auth/register` | — | Create an account, returns tokens |
| POST | `/api/v1/auth/login` | — | Returns tokens |
| GET | `/api/v1/auth/me` | Bearer | Current user |
| POST | `/api/v1/detect` | optional | **Primary detection endpoint** |
| POST | `/predict` | optional | Legacy shape, deprecated |
| GET | `/api/v1/history` | Bearer | This user's detections |
| GET/DELETE | `/api/v1/history/{id}` | Bearer | One detection |
| GET | `/api/v1/plants` | — | Supported plants |
| GET | `/api/v1/diseases`, `/diseases/{id}` | — | Disease knowledge base |
| GET/POST/DELETE | `/api/v1/favorites`, `/favorites/{id}` | Bearer | Saved items |

### `POST /api/v1/detect`

`multipart/form-data` with a `file` field. Optional `?top_k=` (1–20, default 5).

```json
{
  "success": true,
  "prediction": {
    "disease": "Early blight",
    "plant": "Tomato",
    "confidence": 0.8712,
    "is_healthy": false,
    "is_identifiable": true,
    "risk_level": "medium",
    "description": "...",
    "symptoms": ["..."],
    "treatment": ["..."],
    "prevention": ["..."],
    "scientific_name": "Solanum lycopersicum",
    "class_label": "Tomato___Early_blight"
  },
  "alternatives": [
    {"disease": "Late blight", "plant": "Tomato", "confidence": 0.08,
     "class_label": "Tomato___Late_blight"}
  ],
  "information": {"description": "...", "symptoms": [], "treatment": [], "prevention": []},
  "metadata": {"model_version": "mobilenetv2-20c-v1", "processing_time_ms": 123}
}
```

Three outcomes a client must handle distinctly:

- `is_identifiable: false` — no leaf was found. Ask for a clearer photo; do not
  present a diagnosis, and never show `class_label` to a user.
- `is_healthy: true` — no disease detected.
- otherwise — a disease, with `risk_level` describing agronomic severity.

`confidence` is **model certainty**, not diagnostic certainty. `risk_level` is a
static property of the disease and is deliberately independent of it.

### `GET /health`

```json
{"status": "healthy", "model_loaded": true,
 "model_version": "mobilenetv2-20c-v1", "classes": 20, "database": "connected"}
```

Always returns 200 so the probe is not mistaken for an outage; `status` becomes
`"degraded"` if the model or database is unavailable. No configuration or
secrets are exposed.

## Error responses

Every error uses one envelope:

```json
{"success": false,
 "message": "The uploaded image could not be processed.",
 "error": {"code": "INVALID_IMAGE", "message": "The uploaded image could not be processed."}}
```

Switch on `error.code`; `message` is duplicated at the top level for older
clients.

| Code | Status | Meaning |
|---|---|---|
| `INVALID_IMAGE` | 400 | Not a readable image, or outside the size bounds |
| `FILE_TOO_LARGE` | 413 | Over `MAX_UPLOAD_SIZE_MB` |
| `VALIDATION_ERROR` | 422 | Request body failed validation |
| `UNAUTHORIZED` | 401/403 | Missing, invalid or expired token |
| `NOT_FOUND` | 404 | No such resource |
| `MODEL_UNAVAILABLE` | 503 | Model not loaded yet |
| `PREDICTION_FAILED` | 503 | Inference raised |
| `DATABASE_ERROR` | 500 | Database failure |
| `RATE_LIMITED` | 429 | Reserved — no limiter is built in; set one at the proxy |
| `INTERNAL_ERROR` | 500 | Unhandled |

## Image handling

Uploads are validated by **decoding**, not by trusting the client: format must
be JPEG/PNG/WebP/BMP, dimensions 32–8000 px, size within the limit, and
`Image.MAX_IMAGE_PIXELS` guards decompression bombs.

Images are written to `uploads/` **only** when the detection is persisted for an
authenticated user; the file extension comes from the decoded format, never the
supplied filename. Anonymous scans touch the disk not at all. No filesystem path
is ever returned to a client.

## Model

| Property | Value |
|---|---|
| Architecture | MobileNetV2, transfer-learned |
| Input | 224 × 224 × 3 RGB |
| Preprocessing | `cv2.resize(..., INTER_AREA)` → float32 → `mobilenet_v2.preprocess_input` |
| Output | softmax over 20 classes |
| Labels | `Resources/class_names.json` — **order is significant** |

Class order maps positionally onto output indices; reordering the file silently
mislabels every prediction. `tests/test_metadata.py::test_class_names_and_order_are_unchanged`
pins it so that becomes a test failure rather than a silent bug.

## Tests

```bash
.venv\Scripts\python -m pytest -q
```

15 tests: health, auth, detect (validation, response shape, error codes,
anonymous-upload cleanup) and the model/knowledge-base contract. Detect tests
stub the model — loading 60 MB of weights to assert a float is slow and brittle.

## Deployment

`Dockerfile` and `docker-compose.yaml` are at the repo root:

```bash
docker compose up --build
```

Production checklist:

1. `DEBUG=false` and a real `SECRET_KEY` (startup refuses the placeholder).
2. `CORS_ORIGINS` set to explicit origins.
3. `alembic upgrade head` as part of the release.
4. `DATABASE_URL` pointing at managed Postgres rather than SQLite.
5. Serve over HTTPS and drop `usesCleartextTraffic` from the Android manifest.

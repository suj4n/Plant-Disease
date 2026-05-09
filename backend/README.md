# Backend (Plant Disease API)

This folder contains a small **FastAPI** service that runs inference using your trained Keras model at `../model/best_model.keras`.

## Prerequisites

- Python **3.11 or 3.12** (TensorFlow does **not** currently support Python 3.14)

## Setup (Windows / PowerShell)

From the repo root:

```bash
py -3.11 -m venv backend/.venv
backend/.venv/Scripts/pip install -r backend/requirements.txt
backend/.venv/Scripts/uvicorn backend.app.main:app --reload --port 8000
```

## API

- `GET /health` → basic health check
- `GET /meta` → model label metadata (class list)
- `POST /predict` → multipart form upload with key `file`

Example:

```bash
curl -X POST "http://127.0.0.1:8000/predict?top_k=5" -F "file=@leaf.jpg"
```

Returns JSON:

- `predictions`: array of `{label, probability}`
- `top_label`: best label
- `model_path`: resolved model path used for inference

## Configuration

Copy `backend/.env.example` to `backend/.env` (optional).

Environment variables:

- `MODEL_PATH`: path to `.keras` model (relative to `backend/` or absolute)
- `ALLOW_ORIGINS`: comma-separated origins, or `*`
- `DEFAULT_TOP_K`: default number of predictions to return
- `PRELOAD_MODEL`: `true` to load model at startup (fail fast)
- `MAX_UPLOAD_BYTES`: max upload size (bytes)


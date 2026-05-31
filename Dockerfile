# PlantDoc FastAPI + Keras — deploy on Railway, Render, or Fly.io
# Build context: repository root (needs backend/, Resources/, model/plant_best_model.keras)

FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8000

WORKDIR /app/backend

# OpenCV / TensorFlow runtime libs on slim images
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY backend/ /app/backend/
COPY Resources/ /app/Resources/
COPY model/ /app/model/

RUN mkdir -p /app/backend/data /app/backend/uploads

ENV DEBUG=false \
    MODEL_PATH=/app/model/plant_best_model.keras \
    CLASS_NAMES_PATH=/app/Resources/class_names.json \
    DATABASE_URL=sqlite:////app/backend/data/plantdoc.db \
    UPLOAD_DIR=/app/backend/uploads

EXPOSE 8000

# Model load + TensorFlow init can take a minute on cold start
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5)"

# Railway / Render / Fly set PORT; default 8000 for local docker compose
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]

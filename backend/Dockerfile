FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (needed for OpenCV / image processing)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/app ./app
COPY backend/alembic ./alembic
COPY backend/alembic.ini .

# ✅ COPY ML MODEL + LABELS (IMPORTANT FIX)
COPY model /model
COPY resources /resources

# Create uploads folder (if your API uses it)
RUN mkdir -p uploads

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/model/plant_best_model.keras
ENV CLASS_NAMES_PATH=/resources/class_names.json

# Expose FastAPI port
EXPOSE 8000

# Run API server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
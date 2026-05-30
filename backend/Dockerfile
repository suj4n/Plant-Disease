FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY alembic ./alembic
COPY alembic.ini .

# Model and labels are mounted or copied at build/deploy time
RUN mkdir -p uploads

ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/model/plant_best_model.keras
ENV CLASS_NAMES_PATH=/resources/class_names.json

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

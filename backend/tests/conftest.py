import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
os.environ.setdefault("DATABASE_URL", f"sqlite:///{(BACKEND_ROOT / 'test.db').as_posix()}")
os.environ.setdefault("SECRET_KEY", "test-secret-key-for-pytest-only")


@pytest.fixture(scope="session")
def client() -> TestClient:
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client

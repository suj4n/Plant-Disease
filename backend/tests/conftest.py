import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
# A fresh database per run. The previous persistent test.db meant
# test_register_and_login succeeded once and returned 409 Conflict on every
# subsequent run — the suite only passed if you deleted the file first.
_TEST_DB = BACKEND_ROOT / "test.db"
_TEST_DB.unlink(missing_ok=True)
os.environ.setdefault("DATABASE_URL", f"sqlite:///{_TEST_DB.as_posix()}")
os.environ.setdefault("SECRET_KEY", "test-secret-key-for-pytest-only")


@pytest.fixture(scope="session")
def client() -> TestClient:
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client

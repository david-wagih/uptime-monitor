import os
import tempfile

# Configure before importing the app: tests use a throwaway SQLite file instead of Postgres.
_db_file = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
os.environ["UPTIME_DATABASE_URL"] = f"sqlite:///{_db_file.name}"
os.environ["UPTIME_ADMIN_TOKEN"] = ""

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from uptime import models  # noqa: E402, F401
from uptime.api import app  # noqa: E402
from uptime.db import Base, engine  # noqa: E402


@pytest.fixture(autouse=True)
def fresh_db():
    Base.metadata.create_all(engine)
    yield
    Base.metadata.drop_all(engine)


@pytest.fixture
def client():
    return TestClient(app)

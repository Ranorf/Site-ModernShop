import importlib
from pathlib import Path

import pytest
from fastapi.testclient import TestClient


@pytest.fixture(scope="module")
def client(tmp_path_factory, monkeypatch):
    db_path = tmp_path_factory.mktemp("data") / "test_modernshop.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{db_path}")

    import backend.database as database
    import backend.app as app_module

    importlib.reload(database)
    importlib.reload(app_module)

    with TestClient(app_module.app) as test_client:
        yield test_client

    if Path(db_path).exists():
        Path(db_path).unlink()


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_products_seeded(client):
    response = client.get("/products")
    assert response.status_code == 200
    data = response.json()

    assert len(data) == 3
    accents = {item["accent"] for item in data}
    assert {"#d92bd6", "#a31fdc", "#661f7c"}.issubset(accents)
    assert all(item["in_stock"] for item in data)

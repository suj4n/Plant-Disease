def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200

    body = response.json()
    assert body["status"] in {"healthy", "degraded"}
    assert isinstance(body["model_loaded"], bool)
    assert body["database"] == "connected"
    # No configuration, paths or secrets may leak through the probe.
    assert not any(
        key in body for key in ("secret_key", "database_url", "model_path", "cors_origins")
    )


def test_health_also_mounted_under_v1(client):
    assert client.get("/api/v1/health").status_code == 200

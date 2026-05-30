def test_register_and_login(client):
    payload = {
        "email": "tester@plantdoc.app",
        "username": "tester",
        "password": "securepass123",
    }
    reg = client.post("/api/v1/auth/register", json=payload)
    assert reg.status_code == 201
    assert reg.json()["success"] is True
    assert "access_token" in reg.json()["tokens"]

    login = client.post(
        "/api/v1/auth/login",
        json={"email": payload["email"], "password": payload["password"]},
    )
    assert login.status_code == 200
    token = login.json()["tokens"]["access_token"]

    me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == payload["email"]

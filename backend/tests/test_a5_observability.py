import json
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from test_toko import register


def request_records(capfd):
    return [
        json.loads(line) for line in capfd.readouterr().err.splitlines() if line.startswith("{")
    ]


def test_health_version_and_database_failure(client, monkeypatch):
    result = client.get("/health")
    assert result.json() == {"status": "ok", "database": "ok", "version": "1.0.0"}
    dead = create_engine(
        "postgresql+psycopg2://unused:unused@127.0.0.1:1/unused",
        connect_args={"connect_timeout": 1},
        hide_parameters=True,
    )
    try:
        monkeypatch.setattr(client.app.state, "sessions", sessionmaker(dead))
        result = client.get("/health")
        assert result.status_code == 503
        assert result.json() == {"status": "error", "database": "error", "version": "1.0.0"}
        UUID(result.headers["x-request-id"])
    finally:
        dead.dispose()


def test_json_request_log_has_timing_identity_and_no_secrets(client, account, capfd):
    headers = register(client, account)
    profile = client.get("/auth/me", headers=headers).json()
    result = client.get("/toko/me?api_key=private-query-marker", headers=headers)
    records = request_records(capfd)
    record = next(row for row in records if row.get("path") == "/toko/me")
    assert set(record) == {
        "timestamp",
        "request_id",
        "method",
        "path",
        "status_code",
        "duration_ms",
        "user_id",
    }
    assert record["status_code"] == 200
    assert record["method"] == "GET"
    assert record["duration_ms"] >= 0
    assert record["user_id"] == profile["id"]
    assert record["request_id"] == result.headers["x-request-id"]
    UUID(record["request_id"])
    serialized = json.dumps(records)
    assert "private-query-marker" not in serialized
    assert account["password"] not in serialized
    assert headers["Authorization"] not in serialized


def test_unexpected_error_returns_request_id_and_logs_traceback(client, capfd):
    def broken():
        raise RuntimeError("a5-test-fault")

    client.app.add_api_route("/a5-test-fault", broken, methods=["GET"])
    with TestClient(client.app, raise_server_exceptions=False) as http:
        response = http.get("/a5-test-fault")
    assert response.status_code == 500
    UUID(response.headers["x-request-id"])
    records = request_records(capfd)
    failure = next(row for row in records if "traceback" in row)
    assert "Traceback (most recent call last)" in failure["traceback"]
    assert "a5-test-fault" in failure["traceback"]
    assert any(row.get("status_code") == 500 for row in records)

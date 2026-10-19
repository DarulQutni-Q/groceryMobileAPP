import pytest
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError


def test_database_error_does_not_echo_notification_token(client, account):
    tokens = client.post("/auth/register", json=account).json()
    with client.app.state.engine.begin() as connection:
        connection.execute(
            text(
                "CREATE TRIGGER reject_update BEFORE UPDATE ON users "
                "BEGIN SELECT RAISE(ABORT, 'update rejected'); END"
            )
        )
    marker = "fcm-private-marker-not-for-logs"
    with pytest.raises(SQLAlchemyError) as error:
        client.patch(
            "/auth/fcm-token",
            json={"fcm_token": marker},
            headers={
                "Authorization": f"Bearer {tokens['access_token']}",
            },
        )
    assert marker not in str(error.value)

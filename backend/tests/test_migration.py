import os
import secrets
import subprocess
import sys

from sqlalchemy import create_engine, inspect, select, text

from app.models.user import User


def test_upgrade_preserves_legacy_accounts_and_backfills_store_hours(tmp_path):
    url = f"sqlite:///{tmp_path / 'legacy.db'}"
    env = dict(os.environ, DATABASE_URL=url, JWT_SECRET=secrets.token_urlsafe(48))

    def upgrade(target):
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", target],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )

    upgrade("0001_user")
    engine = create_engine(url)
    with engine.begin() as db:
        db.execute(
            User.__table__.insert(),
            [
                {
                    "nama": "Pemilik Lama",
                    "email": "legacy@example.com",
                    "nama_toko": "Toko Lama",
                    "role": "seller",
                    "auth_provider": "email",
                },
                {
                    "nama": "Google Lama",
                    "email": "google@example.com",
                    "nama_toko": None,
                    "role": "seller",
                    "auth_provider": "google",
                },
            ],
        )
    upgrade("head")
    assert {"toko", "jam_buka", "produk"} <= set(inspect(engine).get_table_names())
    with engine.connect() as db:
        assert len(db.execute(select(User)).all()) == 2
        rows = db.execute(text("SELECT nama, status, radius_km FROM toko ORDER BY nama")).all()
        assert rows == [("Toko Google Lama", "tutup", 5), ("Toko Lama", "tutup", 5)]
        assert db.scalar(text("SELECT COUNT(*) FROM jam_buka WHERE is_tutup")) == 14
    engine.dispose()

import os
import secrets
import subprocess
import sys
from uuid import uuid4

import pytest
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url


@pytest.fixture(params=["sqlite", "postgres"])
def migration_database(request, tmp_path):
    if request.param == "sqlite":
        yield f"sqlite:///{tmp_path / 'indexes.db'}"
        return
    raw = os.environ.get("A2_TEST_POSTGRES_URL")
    if not raw:
        pytest.skip("PostgreSQL migration needs A2_TEST_POSTGRES_URL")
    schema = "a5_migration_" + uuid4().hex
    engine = create_engine(raw, hide_parameters=True)
    with engine.begin() as db:
        db.execute(text(f'CREATE SCHEMA "{schema}"'))
    try:
        yield (
            make_url(raw)
            .update_query_dict({"options": f"-csearch_path={schema}"})
            .render_as_string(hide_password=False)
        )
    finally:
        with engine.begin() as db:
            db.execute(text(f'DROP SCHEMA "{schema}" CASCADE'))
        engine.dispose()


def test_new_indexes_upgrade_downgrade_preserve_data_and_existing_indexes(migration_database):
    env = dict(os.environ, DATABASE_URL=migration_database, JWT_SECRET=secrets.token_urlsafe(48))

    def alembic(*args):
        subprocess.run(
            [sys.executable, "-m", "alembic", *args],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )

    alembic("upgrade", "0003_pesanan")
    engine = create_engine(migration_database, hide_parameters=True)
    try:
        with engine.begin() as db:
            db.execute(
                text(
                    "INSERT INTO users (id,nama,email,role,auth_provider,created_at,updated_at) "
                    "VALUES ('11111111111111111111111111111111','Pemilik','a5@example.com',"
                    "'seller','email',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
                )
            )
        for target in ["head", "0003_pesanan", "head"]:
            alembic("downgrade" if target == "0003_pesanan" else "upgrade", target)
            schema = inspect(engine)
            pesanan = {row["name"] for row in schema.get_indexes("pesanan")}
            produk = {row["name"] for row in schema.get_indexes("produk")}
            assert "ix_pesanan_toko_id" in pesanan
            assert "ix_produk_toko_id" in produk
            assert ("ix_pesanan_status" in pesanan) == (target == "head")
            assert ("ix_produk_kategori" in produk) == (target == "head")
            assert any(
                row["column_names"] == ["email"] for row in schema.get_unique_constraints("users")
            )
            with engine.connect() as db:
                assert db.scalar(text("SELECT COUNT(*) FROM users")) == 1
        alembic("check")
    finally:
        engine.dispose()

import os
import secrets
import subprocess
import sys

from sqlalchemy import create_engine, inspect, text


def test_upgrade_from_a2_adds_orders_without_losing_existing_store(tmp_path):
    url = f"sqlite:///{tmp_path / 'a2.db'}"
    env = dict(os.environ, DATABASE_URL=url, JWT_SECRET=secrets.token_urlsafe(48))

    def upgrade(target):
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", target],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )

    upgrade("0002_toko_produk")
    engine = create_engine(url)
    with engine.begin() as db:
        db.execute(
            text(
                "INSERT INTO users (id,nama,email,role,auth_provider,created_at,updated_at) "
                "VALUES ('11111111111111111111111111111111','Pemilik','a2@example.com',"
                "'seller','email',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
            )
        )
        db.execute(
            text(
                "INSERT INTO toko (id,owner_id,nama,alamat,telepon,kategori,radius_km,"
                "status,metode_kirim,created_at,updated_at) VALUES "
                "('22222222222222222222222222222222','11111111111111111111111111111111',"
                "'Toko Lama','','','[]',5,'tutup','[]',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
            )
        )
        db.execute(
            text(
                "INSERT INTO produk (id,toko_id,nama,harga,stok,satuan,kategori,is_tersedia,"
                "created_at,updated_at) VALUES "
                "('33333333333333333333333333333333','22222222222222222222222222222222',"
                "'Beras Lama',15000,5,'kg','Beras',1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
            )
        )
    upgrade("head")
    try:
        assert {"pesanan", "pesanan_item"} <= set(inspect(engine).get_table_names())
        with engine.connect() as db:
            assert db.scalar(text("SELECT COUNT(*) FROM users")) == 1
            assert db.scalar(text("SELECT nama FROM toko")) == "Toko Lama"
            assert db.scalar(text("SELECT harga FROM produk")) == 15000
            assert db.scalar(text("SELECT COUNT(*) FROM pesanan")) == 0
    finally:
        engine.dispose()

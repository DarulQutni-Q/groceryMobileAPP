import uuid
from datetime import datetime, timezone

import sqlalchemy as sa
from alembic import op

revision = "0002_toko_produk"
down_revision = "0001_user"
branch_labels = None
depends_on = None
HARI = ("senin", "selasa", "rabu", "kamis", "jumat", "sabtu", "minggu")


def upgrade():
    toko = op.create_table(
        "toko",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("owner_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False, unique=True),
        sa.Column("nama", sa.String(120), nullable=False),
        sa.Column("logo_url", sa.String(512), nullable=True),
        sa.Column("alamat", sa.Text(), nullable=False),
        sa.Column("telepon", sa.String(32), nullable=False),
        sa.Column("deskripsi", sa.Text(), nullable=True),
        sa.Column("kategori", sa.JSON(), nullable=False),
        sa.Column("radius_km", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(10), nullable=False),
        sa.Column("metode_kirim", sa.JSON(), nullable=False),
        sa.Column("rekening_bank", sa.String(200), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("radius_km BETWEEN 1 AND 10", name="toko_radius"),
        sa.CheckConstraint("status IN ('buka', 'tutup')", name="toko_status"),
    )
    jam = op.create_table(
        "jam_buka",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "toko_id", sa.Uuid(), sa.ForeignKey("toko.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("hari", sa.String(10), nullable=False),
        sa.Column("jam_buka", sa.Time(), nullable=True),
        sa.Column("jam_tutup", sa.Time(), nullable=True),
        sa.Column("is_tutup", sa.Boolean(), nullable=False),
        sa.UniqueConstraint("toko_id", "hari", name="jam_toko_hari"),
        sa.CheckConstraint(
            "is_tutup OR (jam_buka IS NOT NULL AND jam_tutup IS NOT NULL AND jam_buka < jam_tutup)",
            name="jam_urutan",
        ),
    )
    op.create_table(
        "produk",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("toko_id", sa.Uuid(), sa.ForeignKey("toko.id"), nullable=False),
        sa.Column("nama", sa.String(160), nullable=False),
        sa.Column("foto_url", sa.String(512), nullable=True),
        sa.Column("harga", sa.Integer(), nullable=False),
        sa.Column("stok", sa.Integer(), nullable=False),
        sa.Column("satuan", sa.String(10), nullable=False),
        sa.Column("kategori", sa.String(80), nullable=False),
        sa.Column("is_tersedia", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("harga > 0", name="produk_harga"),
        sa.CheckConstraint("stok >= 0", name="produk_stok"),
        sa.CheckConstraint("satuan IN ('kg', 'pcs', 'liter')", name="produk_satuan"),
    )
    op.create_index("ix_produk_toko_id", "produk", ["toko_id"])
    backfill(toko, jam)


def backfill(toko, jam):
    bind = op.get_bind()
    users = sa.table(
        "users",
        sa.column("id", sa.Uuid()),
        sa.column("nama", sa.String()),
        sa.column("nama_toko", sa.String()),
        sa.column("phone", sa.String()),
        sa.column("role", sa.String()),
    )
    for user in bind.execute(sa.select(users).where(users.c.role == "seller")).mappings():
        toko_id = uuid.uuid4()
        now = datetime.now(timezone.utc)
        bind.execute(
            toko.insert().values(
                id=toko_id,
                owner_id=user["id"],
                nama=user["nama_toko"] or f"Toko {user['nama']}"[:120],
                alamat="",
                telepon=user["phone"] or "",
                kategori=[],
                metode_kirim=[],
                radius_km=5,
                status="tutup",
                created_at=now,
                updated_at=now,
            )
        )
        bind.execute(
            jam.insert(),
            [dict(id=uuid.uuid4(), toko_id=toko_id, hari=hari, is_tutup=True) for hari in HARI],
        )


def downgrade():
    op.drop_index("ix_produk_toko_id", table_name="produk")
    op.drop_table("produk")
    op.drop_table("jam_buka")
    op.drop_table("toko")

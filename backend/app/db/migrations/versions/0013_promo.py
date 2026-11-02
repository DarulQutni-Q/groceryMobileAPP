"""Tabel promo per toko (tebus murah + kilat murah)."""

import sqlalchemy as sa
from alembic import op

revision = "0013_promo"
down_revision = "0012_voucher"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "promo",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("toko_id", sa.Uuid(), nullable=False),
        sa.Column("produk_id", sa.Uuid(), nullable=True),
        sa.Column("judul", sa.String(120), nullable=False),
        sa.Column("jenis", sa.String(12), nullable=False),
        sa.Column("harga_promo", sa.Integer(), nullable=False),
        sa.Column("min_belanja", sa.Integer(), nullable=False),
        sa.Column("aktif", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("berakhir_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["toko_id"], ["toko.id"]),
        sa.ForeignKeyConstraint(["produk_id"], ["produk.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_promo_toko_id", "promo", ["toko_id"])
    op.add_column("pesanan", sa.Column("promo_diskon", sa.Integer(), nullable=False, server_default="0"))


def downgrade():
    op.drop_column("pesanan", "promo_diskon")
    op.drop_index("ix_promo_toko_id", table_name="promo")
    op.drop_table("promo")

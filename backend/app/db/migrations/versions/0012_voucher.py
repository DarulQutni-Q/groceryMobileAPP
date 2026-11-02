"""Tabel voucher per toko + kode voucher di pesanan."""

import sqlalchemy as sa
from alembic import op

revision = "0012_voucher"
down_revision = "0011_notifikasi"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "voucher",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("toko_id", sa.Uuid(), nullable=False),
        sa.Column("kode", sa.String(40), nullable=False),
        sa.Column("judul", sa.String(120), nullable=False),
        sa.Column("jenis", sa.String(12), nullable=False),
        sa.Column("persen", sa.Integer(), nullable=False),
        sa.Column("cap", sa.Integer(), nullable=False),
        sa.Column("min_belanja", sa.Integer(), nullable=False),
        sa.Column("max_ongkir", sa.Integer(), nullable=False),
        sa.Column("aktif", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["toko_id"], ["toko.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("toko_id", "kode", name="voucher_kode_per_toko"),
    )
    op.create_index("ix_voucher_toko_id", "voucher", ["toko_id"])
    op.add_column("pesanan", sa.Column("voucher_kode", sa.String(40), nullable=True))


def downgrade():
    op.drop_column("pesanan", "voucher_kode")
    op.drop_index("ix_voucher_toko_id", table_name="voucher")
    op.drop_table("voucher")

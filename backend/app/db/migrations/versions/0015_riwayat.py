"""Tabel riwayat status pesanan."""

import sqlalchemy as sa
from alembic import op

revision = "0015_riwayat"
down_revision = "0014_chat"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "riwayat_status",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("pesanan_id", sa.Uuid(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("keterangan", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["pesanan_id"], ["pesanan.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_riwayat_status_pesanan_id", "riwayat_status", ["pesanan_id"]
    )


def downgrade():
    op.drop_index("ix_riwayat_status_pesanan_id", table_name="riwayat_status")
    op.drop_table("riwayat_status")

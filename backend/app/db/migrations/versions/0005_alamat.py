"""Simpan alamat pengiriman customer."""

import sqlalchemy as sa
from alembic import op

revision = "0005_alamat"
down_revision = "0004_query_indexes"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "alamat",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("label", sa.String(40), nullable=False),
        sa.Column("nama_penerima", sa.String(120), nullable=False),
        sa.Column("no_hp", sa.String(32), nullable=False),
        sa.Column("alamat_lengkap", sa.String(2000), nullable=False),
        sa.Column("patokan", sa.String(500)),
        sa.Column("latitude", sa.Float()),
        sa.Column("longitude", sa.Float()),
        sa.Column("is_utama", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_alamat_user_id", "alamat", ["user_id"])


def downgrade():
    op.drop_table("alamat")

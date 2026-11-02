"""Kolom koordinat toko (dipilih seller lewat peta, default kosong)."""

import sqlalchemy as sa
from alembic import op

revision = "0016_toko_koordinat"
down_revision = "0015_riwayat"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("toko", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("toko", sa.Column("longitude", sa.Float(), nullable=True))


def downgrade():
    op.drop_column("toko", "longitude")
    op.drop_column("toko", "latitude")

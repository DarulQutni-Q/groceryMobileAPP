"""Tabel chat per pesanan (pelanggan <-> toko)."""

import sqlalchemy as sa
from alembic import op

revision = "0014_chat"
down_revision = "0013_promo"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "chat_pesan",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("pesanan_id", sa.Uuid(), nullable=False),
        sa.Column("pengirim_id", sa.Uuid(), nullable=False),
        sa.Column("pengirim_peran", sa.String(12), nullable=False),
        sa.Column("isi", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["pesanan_id"], ["pesanan.id"]),
        sa.ForeignKeyConstraint(["pengirim_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_chat_pesan_pesanan_id", "chat_pesan", ["pesanan_id"])


def downgrade():
    op.drop_index("ix_chat_pesan_pesanan_id", table_name="chat_pesan")
    op.drop_table("chat_pesan")

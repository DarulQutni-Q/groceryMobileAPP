"""Tabel notifikasi tersimpan."""

import sqlalchemy as sa
from alembic import op

revision = "0011_notifikasi"
down_revision = "0010_password_reset_otp"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "notifikasi",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("pesanan_id", sa.Uuid(), nullable=True),
        sa.Column("judul", sa.String(160), nullable=False),
        sa.Column("isi", sa.Text(), nullable=False),
        sa.Column("dibaca", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["pesanan_id"], ["pesanan.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_notifikasi_user_id", "notifikasi", ["user_id"])


def downgrade():
    op.drop_index("ix_notifikasi_user_id", table_name="notifikasi")
    op.drop_table("notifikasi")

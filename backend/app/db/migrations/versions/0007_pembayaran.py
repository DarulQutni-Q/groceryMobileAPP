"""Simpan invoice dan reservasi stok checkout."""

import sqlalchemy as sa
from alembic import op

revision = "0007_pembayaran"
down_revision = "0006_checkout_attempt"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "pembayaran",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "pesanan_id", sa.Uuid(), sa.ForeignKey("pesanan.id"), nullable=False, unique=True
        ),
        sa.Column("xendit_id", sa.String(120), unique=True),
        sa.Column("external_id", sa.String(80), nullable=False, unique=True),
        sa.Column("metode", sa.String(20), nullable=False),
        sa.Column("status", sa.String(12), nullable=False),
        sa.Column("jumlah", sa.Integer(), nullable=False),
        sa.Column("payment_url", sa.String(2048)),
        sa.Column("paid_at", sa.DateTime(timezone=True)),
        sa.Column("stok_direservasi", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("jumlah > 0", name="pembayaran_jumlah"),
        sa.CheckConstraint(
            "status IN ('pending','paid','expired','failed')", name="pembayaran_status"
        ),
    )


def downgrade():
    op.drop_table("pembayaran")

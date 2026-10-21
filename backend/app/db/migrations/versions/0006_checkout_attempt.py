"""Catat kunci checkout sebelum panggilan gateway."""

import sqlalchemy as sa
from alembic import op

revision = "0006_checkout_attempt"
down_revision = "0005_alamat"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "checkout_attempt",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("request_key", sa.String(80), nullable=False, unique=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("fingerprint", sa.String(64), nullable=False),
        sa.Column("external_id", sa.String(80), nullable=False, unique=True),
        sa.Column("jumlah", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_checkout_attempt_user_id", "checkout_attempt", ["user_id"])


def downgrade():
    op.drop_table("checkout_attempt")

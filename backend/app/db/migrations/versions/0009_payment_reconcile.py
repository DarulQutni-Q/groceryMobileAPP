"""Tandai dana masuk setelah pesanan dibatalkan."""

import sqlalchemy as sa
from alembic import op

revision = "0009_payment_reconcile"
down_revision = "0008_attempt_outcome"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "pembayaran",
        sa.Column("perlu_rekonsiliasi", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade():
    op.drop_column("pembayaran", "perlu_rekonsiliasi")

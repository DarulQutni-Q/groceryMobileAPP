"""Catat hasil gateway yang perlu dipulihkan."""

import sqlalchemy as sa
from alembic import op

revision = "0008_attempt_outcome"
down_revision = "0007_pembayaran"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("checkout_attempt", sa.Column("xendit_id", sa.String(120)))
    op.create_unique_constraint("uq_attempt_xendit", "checkout_attempt", ["xendit_id"])
    op.add_column("checkout_attempt", sa.Column("remote_status", sa.String(12)))
    op.add_column(
        "checkout_attempt",
        sa.Column("perlu_rekonsiliasi", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade():
    op.drop_column("checkout_attempt", "perlu_rekonsiliasi")
    op.drop_column("checkout_attempt", "remote_status")
    op.drop_constraint("uq_attempt_xendit", "checkout_attempt", type_="unique")
    op.drop_column("checkout_attempt", "xendit_id")

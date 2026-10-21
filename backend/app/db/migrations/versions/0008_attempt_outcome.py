"""Catat hasil gateway yang perlu dipulihkan."""

import sqlalchemy as sa
from alembic import op

revision = "0008_attempt_outcome"
down_revision = "0007_pembayaran"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("checkout_attempt") as batch:
        batch.add_column(sa.Column("xendit_id", sa.String(120)))
        batch.create_unique_constraint("uq_attempt_xendit", ["xendit_id"])
        batch.add_column(sa.Column("remote_status", sa.String(12)))
        batch.add_column(
            sa.Column("perlu_rekonsiliasi", sa.Boolean(), nullable=False, server_default=sa.false())
        )


def downgrade():
    with op.batch_alter_table("checkout_attempt") as batch:
        batch.drop_column("perlu_rekonsiliasi")
        batch.drop_column("remote_status")
        batch.drop_constraint("uq_attempt_xendit", type_="unique")
        batch.drop_column("xendit_id")

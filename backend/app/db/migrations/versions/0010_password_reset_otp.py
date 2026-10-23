"""Tabel OTP reset kata sandi."""

import sqlalchemy as sa
from alembic import op

revision = "0010_password_reset_otp"
down_revision = "0009_payment_reconcile"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "password_reset_otps",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("code", sa.String(6), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_password_reset_otps_email", "password_reset_otps", ["email"])


def downgrade():
    op.drop_index("ix_password_reset_otps_email", table_name="password_reset_otps")
    op.drop_table("password_reset_otps")

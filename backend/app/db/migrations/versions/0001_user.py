import sqlalchemy as sa
from alembic import op

revision = "0001_user"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("nama", sa.String(120), nullable=False),
        sa.Column("email", sa.String(254), nullable=False, unique=True),
        sa.Column("phone", sa.String(32), nullable=True, unique=True),
        sa.Column("password_hash", sa.String(128), nullable=True),
        sa.Column("role", sa.String(20), nullable=False),
        sa.Column("auth_provider", sa.String(20), nullable=False),
        sa.Column("google_subject", sa.String(255), nullable=True, unique=True),
        sa.Column("nama_toko", sa.String(120), nullable=True),
        sa.Column("fcm_token", sa.String(4096), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    op.drop_table("users")

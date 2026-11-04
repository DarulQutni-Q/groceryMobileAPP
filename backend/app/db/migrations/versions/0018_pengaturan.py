"""Tabel pengaturan key-value untuk kontrol admin dashboard.

Dipakai versi minimum aplikasi (override env) dan pengaturan admin
lainnya nanti. Tanpa data awal: tidak ada baris berarti pakai env.
"""

import sqlalchemy as sa
from alembic import op

revision = "0018_pengaturan"
down_revision = "0017_voucher_persen_saja"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "pengaturan",
        sa.Column("kunci", sa.String(64), primary_key=True),
        sa.Column("nilai", sa.String(255), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    op.drop_table("pengaturan")

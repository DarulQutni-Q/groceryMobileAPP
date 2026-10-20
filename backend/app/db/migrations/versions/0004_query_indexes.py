"""Tambah index filter status pesanan dan kategori produk."""

from alembic import op

revision = "0004_query_indexes"
down_revision = "0003_pesanan"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index("ix_pesanan_status", "pesanan", ["status"])
    op.create_index("ix_produk_kategori", "produk", ["kategori"])


def downgrade():
    op.drop_index("ix_produk_kategori", table_name="produk")
    op.drop_index("ix_pesanan_status", table_name="pesanan")

import sqlalchemy as sa
from alembic import op

revision = "0003_pesanan"
down_revision = "0002_toko_produk"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "pesanan",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("kode", sa.String(8), nullable=False, unique=True),
        sa.Column("customer_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("toko_id", sa.Uuid(), sa.ForeignKey("toko.id"), nullable=False),
        sa.Column("status", sa.String(12), nullable=False),
        sa.Column("alamat_kirim", sa.Text(), nullable=False),
        sa.Column("catatan", sa.Text(), nullable=True),
        sa.Column("metode_kirim", sa.String(80), nullable=False),
        sa.Column("slot_waktu", sa.String(120), nullable=False),
        sa.Column("subtotal", sa.Integer(), nullable=False),
        sa.Column("diskon", sa.Integer(), nullable=False),
        sa.Column("ongkir", sa.Integer(), nullable=False),
        sa.Column("biaya_layanan", sa.Integer(), nullable=False),
        sa.Column("total", sa.Integer(), nullable=False),
        sa.Column("tolak_alasan", sa.Text(), nullable=True),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('baru','diproses','dikemas','diantar','selesai','dibatalkan','ditolak')",
            name="pesanan_status",
        ),
        sa.CheckConstraint(
            "subtotal >= 0 AND diskon >= 0 AND ongkir >= 0 AND biaya_layanan >= 0",
            name="pesanan_biaya",
        ),
        sa.CheckConstraint(
            "total = subtotal - diskon + ongkir + biaya_layanan AND total >= 0",
            name="pesanan_total",
        ),
    )
    op.create_index("ix_pesanan_toko_id", "pesanan", ["toko_id"])
    op.create_table(
        "pesanan_item",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "pesanan_id", sa.Uuid(), sa.ForeignKey("pesanan.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "produk_id", sa.Uuid(), sa.ForeignKey("produk.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("nama_snapshot", sa.String(160), nullable=False),
        sa.Column("harga_snapshot", sa.Integer(), nullable=False),
        sa.Column("qty", sa.Integer(), nullable=False),
        sa.CheckConstraint("qty > 0 AND harga_snapshot > 0", name="pesanan_item_jumlah"),
    )
    op.create_index("ix_pesanan_item_pesanan_id", "pesanan_item", ["pesanan_id"])


def downgrade():
    op.drop_index("ix_pesanan_item_pesanan_id", table_name="pesanan_item")
    op.drop_table("pesanan_item")
    op.drop_index("ix_pesanan_toko_id", table_name="pesanan")
    op.drop_table("pesanan")

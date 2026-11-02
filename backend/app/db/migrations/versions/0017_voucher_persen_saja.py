"""Hapus jenis voucher gratis_ongkir, tinggal persen.

Catatan: sqlite tidak bisa ALTER constraint bernama (dan tabel di tes
dibuat dari model, bukan migrasi), jadi cabang sqlite sengaja no-op.
Di produksi (postgres) tabel voucher ternyata tidak pernah punya
constraint voucher_jenis (migrasi 0012 tidak membawanya), jadi upgrade
menghapus dulu bila ada, lalu menambah constraint persen saja.
"""

from alembic import op

revision = "0017_voucher_persen_saja"
down_revision = "0016_toko_koordinat"
branch_labels = None
depends_on = None


def _postgres_only():
    return op.get_bind().dialect.name != "sqlite"


def upgrade():
    if not _postgres_only():
        return
    op.execute("ALTER TABLE voucher DROP CONSTRAINT IF EXISTS voucher_jenis")
    op.create_check_constraint(
        "voucher_jenis", "voucher", "jenis IN ('persen')"
    )


def downgrade():
    if not _postgres_only():
        return
    op.execute("ALTER TABLE voucher DROP CONSTRAINT IF EXISTS voucher_jenis")

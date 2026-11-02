"""Perbandingan versi semver untuk gerbang force-update.

Aturan: "1.2.3" dibanding per komponen numerik; sufiks build ("+1")
diabaikan; komponen yang hilang dianggap 0 ("1.2" == "1.2.0"). Versi yang
tidak bisa diparse menghasilkan None dan pemanggil harus fail-open
(aplikasi tetap jalan) — versi rusak tidak boleh mengunci user keluar.
"""


def parse_versi(versi):
    """Kembalikan tuple (mayor, minor, patch) atau None kalau tak valid."""
    if not isinstance(versi, str) or not versi.strip():
        return None
    inti = versi.strip().split("+", 1)[0]
    bagian = inti.split(".")
    if len(bagian) > 3 or not all(b.isdigit() for b in bagian):
        return None
    angka = [int(b) for b in bagian] + [0] * (3 - len(bagian))
    return tuple(angka)


def wajib_update(versi_saat_ini, versi_minimum):
    """True kalau versi saat ini LEBIH LAMA dari minimum. Fail-open."""
    saat_ini = parse_versi(versi_saat_ini)
    minimum = parse_versi(versi_minimum)
    if saat_ini is None or minimum is None:
        return False
    return saat_ini < minimum

/// Voucher dari backend (milik satu toko). Satu-satunya jenis backend
/// adalah 'persen'; 'tanpa' hanya sentinel lokal untuk "hapus pilihan".
class Voucher {
  const Voucher({
    required this.id,
    required this.tokoId,
    required this.kode,
    required this.judul,
    required this.jenis,
    this.persen = 0,
    this.cap = 0,
    this.minBelanja = 0,
    this.maxOngkir = 0,
    this.aktif = true,
    this.createdAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'] as String,
    tokoId: json['toko_id'] as String,
    kode: json['kode'] as String,
    judul: json['judul'] as String,
    jenis: json['jenis'] as String,
    persen: (json['persen'] as num?)?.toInt() ?? 0,
    cap: (json['cap'] as num?)?.toInt() ?? 0,
    minBelanja: (json['min_belanja'] as num?)?.toInt() ?? 0,
    maxOngkir: (json['max_ongkir'] as num?)?.toInt() ?? 0,
    aktif: json['aktif'] as bool? ?? true,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.tryParse(json['created_at'] as String),
  );

  /// Sentinel untuk "Tanpa voucher" (menghapus pilihan).
  static const tanpa = Voucher(
    id: 'tanpa',
    tokoId: '',
    kode: 'TANPA',
    judul: 'Tanpa voucher',
    jenis: 'tanpa',
  );

  final String id, tokoId, kode, judul, jenis;
  final int persen, cap, minBelanja, maxOngkir;
  final bool aktif;
  final DateTime? createdAt;

  bool get isTanpa => jenis == 'tanpa';

  /// Potongan tagihan voucher persen, dibatasi cap dan minimal belanja.
  /// Aturan yang sama dipakai backend; UI hanya menampilkannya, penagihan
  /// memakai angka dari preview backend.
  int potonganTagihan(int subtotal) {
    if (jenis != 'persen') return 0;
    if (subtotal < minBelanja) return 0;
    final hitung = subtotal * persen ~/ 100;
    return hitung > cap ? cap : hitung;
  }

  /// Apakah voucher ini bisa dipakai untuk [subtotal] sekarang.
  bool memenuhiSyarat(int subtotal) => subtotal >= minBelanja;
}

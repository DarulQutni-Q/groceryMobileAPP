class Produk {
  const Produk({
    required this.id,
    required this.tokoId,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.satuan,
    required this.kategori,
    required this.isTersedia,
    this.fotoUrl,
  });
  final String id, tokoId, nama, satuan, kategori;
  final String? fotoUrl;
  final int harga, stok;
  final bool isTersedia;

  factory Produk.fromJson(Map<String, dynamic> json) => Produk(
    id: json['id'] as String,
    tokoId: json['toko_id'] as String,
    nama: json['nama'] as String,
    fotoUrl: json['foto_url'] as String?,
    harga: json['harga'] as int,
    stok: json['stok'] as int,
    satuan: json['satuan'] as String,
    kategori: json['kategori'] as String,
    isTersedia: json['is_tersedia'] as bool,
  );
}

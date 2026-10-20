class PenjualanHarian {
  const PenjualanHarian({required this.tanggal, required this.total});
  final DateTime tanggal;
  final int total;

  factory PenjualanHarian.fromJson(Map<String, dynamic> json) =>
      PenjualanHarian(
        tanggal: DateTime.parse(json['tanggal'] as String),
        total: json['total'] as int,
      );
}

class RingkasanLaporan {
  const RingkasanLaporan({
    required this.totalPenjualan,
    required this.jumlahPesanan,
    required this.jumlahProdukTerjual,
    required this.perbandinganPersen,
    required this.penjualanPerHari,
    this.adaPembanding = false,
  });
  final int totalPenjualan, jumlahPesanan, jumlahProdukTerjual;
  final double perbandinganPersen;
  final bool adaPembanding;
  final List<PenjualanHarian> penjualanPerHari;

  factory RingkasanLaporan.fromJson(Map<String, dynamic> json) =>
      RingkasanLaporan(
        totalPenjualan: json['total_penjualan'] as int,
        jumlahPesanan: json['jumlah_pesanan'] as int,
        jumlahProdukTerjual: json['jumlah_produk_terjual'] as int,
        perbandinganPersen: (json['perbandingan_minggu_lalu'] as num)
            .toDouble(),
        adaPembanding: json['ada_pembanding'] as bool? ?? false,
        penjualanPerHari: (json['penjualan_per_hari'] as List)
            .map((day) => PenjualanHarian.fromJson(day as Map<String, dynamic>))
            .toList(),
      );
}

class ProdukTerlaris {
  const ProdukTerlaris({
    required this.nama,
    required this.totalQty,
    required this.totalRupiah,
    this.produkId,
    this.fotoUrl,
  });
  final String? produkId, fotoUrl;
  final String nama;
  final int totalQty, totalRupiah;

  factory ProdukTerlaris.fromJson(Map<String, dynamic> json) => ProdukTerlaris(
    produkId: json['produk_id'] as String?,
    nama: json['nama'] as String,
    fotoUrl: json['foto_url'] as String?,
    totalQty: json['total_qty'] as int,
    totalRupiah: json['total_rupiah'] as int,
  );
}

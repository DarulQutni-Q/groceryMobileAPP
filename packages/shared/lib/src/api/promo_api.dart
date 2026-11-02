import '../models/produk.dart';
import '../models/promo.dart';
import 'api_client.dart';

/// Banner promo beranda: promo aktif toko dipetakan ke kartu banner.
/// Tidak ada lagi banner demo: kalau tidak ada promo aktif, daftar kosong.
class PromoApi {
  PromoApi(this.client);
  final ApiClient client;

  Future<List<Promo>> list() async {
    final data = (await client.dio.get<List<dynamic>>('/promo/aktif')).data!;
    return data.map((item) {
      final row = item as Map<String, dynamic>;
      final produk = row['produk'] as Map<String, dynamic>?;
      final toko = row['toko_nama'] as String?;
      final deskripsi = produk == null
          ? (toko == null ? row['judul'] as String : '${row['judul']} • $toko')
          : '${produk['nama']} • Rp ${row['harga_promo']}'
              '${toko == null ? '' : ' • $toko'}';
      return Promo(
        id: row['id'] as String,
        judul: row['judul'] as String,
        deskripsi: deskripsi,
        labelTombol: 'Lihat Promo',
        isDemo: false,
      );
    }).toList();
  }
}

/// Promo harga (tebus murah / kilat murah) lengkap dengan snapshot produk.
class PromoHarga {
  const PromoHarga({
    required this.id,
    required this.tokoId,
    required this.tokoNama,
    required this.produkId,
    required this.judul,
    required this.jenis,
    required this.hargaPromo,
    required this.minBelanja,
    required this.aktif,
    required this.produk,
    this.berakhirAt,
  });

  factory PromoHarga.fromJson(Map<String, dynamic> json) {
    final produk = json['produk'] as Map<String, dynamic>?;
    return PromoHarga(
      id: json['id'] as String,
      tokoId: json['toko_id'] as String,
      tokoNama: json['toko_nama'] as String? ?? '',
      produkId: json['produk_id'] as String? ?? '',
      judul: json['judul'] as String,
      jenis: json['jenis'] as String,
      hargaPromo: (json['harga_promo'] as num).toInt(),
      minBelanja: (json['min_belanja'] as num?)?.toInt() ?? 0,
      aktif: json['aktif'] as bool? ?? true,
      berakhirAt: json['berakhir_at'] == null
          ? null
          : DateTime.tryParse(json['berakhir_at'] as String),
      produk: produk == null
          ? null
          : Produk(
              id: produk['id'] as String,
              tokoId: produk['toko_id'] as String,
              nama: produk['nama'] as String,
              harga: (produk['harga'] as num).toInt(),
              stok: (produk['stok'] as num).toInt(),
              satuan: produk['satuan'] as String,
              kategori: produk['kategori'] as String? ?? '',
              isTersedia: produk['is_tersedia'] as bool? ?? true,
              fotoUrl: produk['foto_url'] as String?,
            ),
    );
  }

  final String id, tokoId, tokoNama, produkId, judul, jenis;
  final int hargaPromo, minBelanja;
  final bool aktif;
  final DateTime? berakhirAt;
  final Produk? produk;
}

class PromoHargaApi {
  PromoHargaApi(this.client);
  final ApiClient client;

  Future<List<PromoHarga>> listAktif() async {
    final data = (await client.dio.get<List<dynamic>>('/promo/aktif')).data!;
    return data
        .map((item) => PromoHarga.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromoHarga>> listMine() async {
    final data = (await client.dio.get<List<dynamic>>('/promo')).data!;
    return data
        .map((item) => PromoHarga.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PromoHarga> create(Map<String, dynamic> data) async {
    final result = (await client.dio.post<dynamic>('/promo', data: data)).data;
    return PromoHarga.fromJson(result as Map<String, dynamic>);
  }

  Future<PromoHarga> setAktif(String id, bool aktif) async {
    final result = (await client.dio.patch<dynamic>(
      '/promo/$id',
      data: {'aktif': aktif},
    ))
        .data;
    return PromoHarga.fromJson(result as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await client.dio.delete<dynamic>('/promo/$id');
  }
}

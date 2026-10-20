import '../models/laporan.dart';
import 'api_client.dart';

class LaporanApi {
  LaporanApi(this.client);
  final ApiClient client;

  Future<RingkasanLaporan> getRingkasan({String range = '7h'}) async =>
      RingkasanLaporan.fromJson(
        (await client.dio.get<Map<String, dynamic>>(
          '/laporan/ringkasan',
          queryParameters: {'range': range},
        )).data!,
      );

  Future<List<ProdukTerlaris>> getProdukTerlaris({
    String range = '7h',
    int limit = 5,
  }) async {
    final rows = (await client.dio.get<List<dynamic>>(
      '/laporan/produk-terlaris',
      queryParameters: {'range': range, 'limit': limit},
    )).data!;
    return rows
        .map((row) => ProdukTerlaris.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

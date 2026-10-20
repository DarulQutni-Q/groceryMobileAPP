import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

void main() {
  test(
    'report API parses totals, calendar dates and deleted products',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.example.com',
          extra: {'skipAuth': true},
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                data: request.path.endsWith('ringkasan')
                    ? {
                        'total_penjualan': 110500,
                        'jumlah_pesanan': 3,
                        'jumlah_produk_terjual': 7,
                        'perbandingan_minggu_lalu': -10.5,
                        'ada_pembanding': true,
                        'penjualan_per_hari': [
                          {'tanggal': '2026-10-20', 'total': 110500},
                        ],
                      }
                    : [
                        {
                          'produk_id': null,
                          'nama': 'Beras',
                          'foto_url': null,
                          'total_qty': 5,
                          'total_rupiah': 75000,
                        },
                      ],
              ),
            );
          },
        ),
      );
      final api = LaporanApi(
        ApiClient(
          baseUrl: dio.options.baseUrl,
          dio: dio,
          storage: SecureStorage(),
        ),
      );
      final summary = await api.getRingkasan(range: '30h');
      expect(summary.totalPenjualan, 110500);
      expect(summary.jumlahPesanan, 3);
      expect(summary.jumlahProdukTerjual, 7);
      expect(summary.perbandinganPersen, -10.5);
      expect(summary.adaPembanding, isTrue);
      expect(summary.penjualanPerHari.single.tanggal, DateTime(2026, 10, 20));
      expect(summary.penjualanPerHari.single.total, 110500);
      final ranking = await api.getProdukTerlaris(range: '30h', limit: 6);
      expect(ranking.single.produkId, isNull);
      expect(ranking.single.fotoUrl, isNull);
      expect(ranking.single.nama, 'Beras');
      expect(ranking.single.totalQty, 5);
      expect(ranking.single.totalRupiah, 75000);
      expect(requests[0].path, '/laporan/ringkasan');
      expect(requests[0].queryParameters, {'range': '30h'});
      expect(requests[1].path, '/laporan/produk-terlaris');
      expect(requests[1].queryParameters, {'range': '30h', 'limit': 6});
      await api.getRingkasan();
      await api.getProdukTerlaris();
      expect(requests[2].queryParameters, {'range': '7h'});
      expect(requests[3].queryParameters, {'range': '7h', 'limit': 5});
      dio.close();
    },
  );
}

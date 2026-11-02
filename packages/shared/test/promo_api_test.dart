import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

Map<String, dynamic> samplePromoHarga(String jenis) => {
  'id': 'pr-$jenis',
  'toko_id': 't1',
  'toko_nama': 'Toko Uji',
  'produk_id': 'p1',
  'judul': jenis == 'tebus' ? 'Tebus Biskuit 5rb' : 'Kilat Kerupuk 1rb',
  'jenis': jenis,
  'harga_promo': 5000,
  'min_belanja': 0,
  'aktif': true,
  'berakhir_at': null,
  'created_at': '2026-11-02T00:00:00Z',
  'produk': {
    'id': 'p1',
    'toko_id': 't1',
    'nama': 'Biskuit',
    'harga': 20000,
    'foto_url': null,
    'satuan': 'pcs',
    'kategori': 'Camilan',
    'stok': 10,
    'is_tersedia': true,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test('promo API memakai path backend dan banner dipetakan dari promo aktif', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final calls = <String>[];
    dio.httpClientAdapter = TestAdapter((request) async {
      calls.add('${request.method} ${request.path}');
      if (request.path == '/promo/aktif') {
        return jsonBody([samplePromoHarga('tebus')], 200);
      }
      if (request.path == '/promo' && request.method == 'POST') {
        return jsonBody(samplePromoHarga('kilat'), 201);
      }
      if (request.path == '/promo/pr-tebus' && request.method == 'PATCH') {
        final row = samplePromoHarga('tebus')..['aktif'] = false;
        return jsonBody(row, 200);
      }
      if (request.path == '/promo/pr-tebus' && request.method == 'DELETE') {
        return jsonBody({}, 204);
      }
      return jsonBody({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      storage: SecureStorage(),
      dio: dio,
    );

    final banners = await PromoApi(client).list();
    expect(banners, hasLength(1));
    expect(banners.first.judul, 'Tebus Biskuit 5rb');
    expect(banners.first.deskripsi, contains('Biskuit'));
    expect(banners.first.deskripsi, contains('Rp 5000'));
    expect(banners.first.isDemo, isFalse);

    final harga = PromoHargaApi(client);
    final aktif = await harga.listAktif();
    expect(aktif.first.produk?.nama, 'Biskuit');
    expect(aktif.first.hargaPromo, 5000);
    final created = await harga.create({'judul': 'Kilat'});
    expect(created.jenis, 'kilat');
    final off = await harga.setAktif('pr-tebus', false);
    expect(off.aktif, isFalse);
    await harga.delete('pr-tebus');

    expect(calls, [
      'GET /promo/aktif',
      'GET /promo/aktif',
      'POST /promo',
      'PATCH /promo/pr-tebus',
      'DELETE /promo/pr-tebus',
    ]);
  });
}

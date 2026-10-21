import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const product = {
    'id': 'p1',
    'toko_id': 't1',
    'nama': 'Indomie Spesial',
    'foto_url': null,
    'harga': 16200,
    'stok': 25,
    'satuan': 'pcs',
    'kategori': 'Mie',
    'is_tersedia': true,
  };
  const store = {
    'id': 't1',
    'nama': 'Toko Uji',
    'logo_url': null,
    'alamat': 'Jalan Uji',
    'telepon': '',
    'kategori': ['Sembako'],
    'radius_km': 5,
    'status': 'buka',
    'metode_kirim': ['Instant'],
    'jam_buka': '08:00:00',
    'jam_tutup': '23:00:00',
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test('customer catalog requests explicit pagination and preserves search store and category', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((request) async {
      expect(request.path, '/produk');
      expect(request.queryParameters, {
        'q': 'indomie',
        'kategori': 'Mie',
        'toko_id': 't1',
        'page': 2,
        'per_page': 5,
      });
      return jsonBody({
        'data': [product],
        'meta': {'page': 2, 'per_page': 5, 'total': 12, 'total_pages': 3},
      }, 200);
    });
    final api = ProdukApi(
      ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      ),
    );
    final result = await api.listHalaman(
      q: 'indomie',
      kategori: 'Mie',
      tokoId: 't1',
      page: 2,
      perPage: 5,
    );
    expect(result.data.single.id, 'p1');
    expect(result.page, 2);
    expect(result.total, 12);
    expect(result.adaBerikutnya, isTrue);
  });

  test(
    'default catalog pagination categories and demo promos use existing client',
    () async {
      final calls = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = TestAdapter((request) async {
        calls.add(request.path);
        if (request.path == '/kategori') return jsonBody(['Beras', 'Mie'], 200);
        if (request.path == '/promo')
          return jsonBody([
            {
              'id': 'demo',
              'judul': 'Promo Spesial',
              'deskripsi': 'Voucher demo',
              'label_tombol': 'Klaim Semua Voucher',
              'is_demo': true,
            },
          ], 200);
        expect(request.queryParameters, {'page': 1, 'per_page': 20});
        return jsonBody({
          'data': [product],
          'meta': {'page': 1, 'per_page': 20, 'total': 1, 'total_pages': 1},
        }, 200);
      });
      final client = ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      );
      expect((await ProdukApi(client).listHalaman()).adaBerikutnya, isFalse);
      expect(await ProdukApi(client).kategori(), ['Beras', 'Mie']);
      final promo = (await PromoApi(client).list()).single;
      expect(promo.isDemo, isTrue);
      expect(promo.labelTombol, 'Klaim Semua Voucher');
      expect(calls, ['/produk', '/kategori', '/promo']);
    },
  );

  test('public store list and detail parse optional hours without seller-only fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter(
      (request) async => jsonBody(
        request.path == '/toko'
            ? {
                'data': [store],
                'meta': {
                  'page': 1,
                  'per_page': 20,
                  'total': 1,
                  'total_pages': 1,
                },
              }
            : {
                ...store,
                'produk': [product],
                'meta': {
                  'page': 1,
                  'per_page': 20,
                  'total': 1,
                  'total_pages': 1,
                },
              },
        200,
      ),
    );
    final api = TokoApi(
      ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      ),
    );
    expect((await api.list()).data.single.nama, 'Toko Uji');
    final toko = await api.detail('t1');
    expect(toko.jamBuka, '08:00:00');
    expect(toko.jamTutup, '23:00:00');
    expect(toko.rekeningBank, isNull);
  });
}

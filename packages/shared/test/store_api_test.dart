import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('multipart upload is replayed once after token refresh', () async {
    final saved = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'write') saved[key] = args['value'] as String;
            if (call.method == 'read') return saved[key];
            if (call.method == 'delete') saved.remove(key);
            return null;
          },
        );
    final storage = SecureStorage();
    await storage.saveSession('old-access', 'old-refresh');
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((request) async {
      calls++;
      return jsonBody({'ok': true}, calls == 1 ? 401 : 200);
    });
    final refresh = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    refresh.httpClientAdapter = TestAdapter(
      (_) async => jsonBody({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }, 200),
    );
    final client = ApiClient(
      baseUrl: dio.options.baseUrl,
      dio: dio,
      refreshDio: refresh,
      storage: storage,
    );
    final result = await client.dio.post<Map<String, dynamic>>(
      '/produk/p1/foto',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes([1, 2], filename: 'photo.png'),
      }),
    );
    expect(result.statusCode, 200);
    expect(calls, 2);
    expect(await storage.readAccessToken(), 'new-access');
  });
  test(
    'store and product APIs preserve fields, filters and multipart',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null,
          );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      final toko = {
        'id': 't1',
        'nama': 'Toko Uji',
        'alamat': 'Jalan Uji',
        'telepon': '081234567890',
        'kategori': ['Sembako'],
        'radius_km': 5,
        'status': 'tutup',
        'metode_kirim': ['Instant'],
      };
      final produk = {
        'id': 'p1',
        'toko_id': 't1',
        'nama': 'Beras',
        'foto_url': '/uploads/u.png',
        'harga': 15000,
        'stok': 4,
        'satuan': 'kg',
        'kategori': 'Beras',
        'is_tersedia': true,
      };
      dio.httpClientAdapter = TestAdapter((request) async {
        if (request.path == '/produk' && request.method == 'GET') {
          expect(request.queryParameters, {'q': 'beras', 'kategori': 'Beras'});
          return jsonBody([produk], 200);
        }
        if (request.path == '/produk/p1/foto') {
          expect(request.data, isA<FormData>());
          expect((request.data as FormData).files.single.key, 'file');
          return jsonBody(produk, 200);
        }
        return jsonBody(toko, 200);
      });
      final client = ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      );
      final profile = await TokoApi(client).getProfil();
      expect(profile.nama, 'Toko Uji');
      expect(profile.kategori, ['Sembako']);
      final products = await ProdukApi(client)
          .list(q: 'beras', kategori: 'Beras');
      expect(products.single.harga, 15000);
      expect(products.single.isTersedia, isTrue);
      final uploaded = await ProdukApi(client)
          .uploadFoto('p1', Uint8List.fromList([1, 2]), 'u.png');
      expect(uploaded.fotoUrl, '/uploads/u.png');
    },
  );
}

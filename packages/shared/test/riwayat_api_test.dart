import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test('pesanan API mengambil riwayat dari jalur backend', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final calls = <String>[];
    dio.httpClientAdapter = TestAdapter((request) async {
      calls.add('${request.method} ${request.path}');
      if (request.path == '/pesanan/order-1/riwayat') {
        return jsonBody([
          {
            'id': 'r1',
            'pesanan_id': 'order-1',
            'status': 'baru',
            'keterangan': null,
            'created_at': '2026-11-02T10:00:00Z',
          },
          {
            'id': 'r2',
            'pesanan_id': 'order-1',
            'status': 'diproses',
            'keterangan': null,
            'created_at': '2026-11-02T10:05:00Z',
          },
        ], 200);
      }
      return jsonBody({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      storage: SecureStorage(),
      dio: dio,
    );
    final rows = await PesananApi(client).riwayat('order-1');
    expect([for (final r in rows) r.status], ['baru', 'diproses']);
    expect(calls, ['GET /pesanan/order-1/riwayat']);
  });
}

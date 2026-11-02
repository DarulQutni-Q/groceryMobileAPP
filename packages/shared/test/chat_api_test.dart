import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

Map<String, dynamic> samplePesan(String peran) => {
  'id': 'm1',
  'pesanan_id': 'order-1',
  'pengirim_id': 'u1',
  'pengirim_peran': peran,
  'isi': 'Halo',
  'created_at': '2026-11-02T10:00:00Z',
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

  test('chat API memakai jalur customer dan toko yang benar', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final calls = <String>[];
    dio.httpClientAdapter = TestAdapter((request) async {
      calls.add('${request.method} ${request.path}');
      if (request.path == '/chat/pesanan/order-1') {
        return jsonBody([samplePesan('toko')], 200);
      }
      if (request.path == '/chat/toko/pesanan/order-1') {
        if (request.method == 'GET') {
          return jsonBody([samplePesan('customer')], 200);
        }
        return jsonBody(samplePesan('toko'), 201);
      }
      return jsonBody({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      storage: SecureStorage(),
      dio: dio,
    );

    final customer = await ChatApi(client).list('order-1');
    expect(customer.first.dariToko, isTrue);
    final toko = ChatApi(client, sisiToko: true);
    final list = await toko.list('order-1');
    expect(list.first.dariToko, isFalse);
    final sent = await toko.kirim('order-1', 'Halo');
    expect(sent.isi, 'Halo');
    expect(calls, [
      'GET /chat/pesanan/order-1',
      'GET /chat/toko/pesanan/order-1',
      'POST /chat/toko/pesanan/order-1',
    ]);
  });
}

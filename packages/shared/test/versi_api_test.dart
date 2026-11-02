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

  test('perluUpdate membandingkan semver dan fail-open', () {
    expect(perluUpdate('0.1.0', '0.2.0'), isTrue);
    expect(perluUpdate('0.2.0', '0.2.0'), isFalse);
    expect(perluUpdate('1.0.0', '0.9.9'), isFalse);
    expect(perluUpdate('0.1.0+1', '0.1.0'), isFalse);
    expect(perluUpdate('rusak', '9.9.9'), isFalse);
  });

  test('VersiApi memetakan /versi-minimum dan gagal fail-open', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((request) async {
      if (request.path == '/versi-minimum') {
        return jsonBody({
          'aplikasi': 'customer',
          'versi_saat_ini': '0.1.0',
          'versi_minimum': '0.2.0',
          'wajib_update': true,
        }, 200);
      }
      return jsonBody({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: SecureStorage(),
      dio: dio,
    );
    client.dio.options.connectTimeout = null;
    client.dio.options.receiveTimeout = null;
    final api = VersiApi(client);
    final hasil = await api.cek('customer', '0.1.0');
    expect(hasil.wajibUpdate, isTrue);
    expect(hasil.versiMinimum, '0.2.0');

    final dioGagal = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dioGagal.httpClientAdapter = TestAdapter(
      (_) async => jsonBody({'detail': 'Server mati'}, 500),
    );
    final clientGagal = ApiClient(
      baseUrl: dioGagal.options.baseUrl,
      storage: SecureStorage(),
      dio: dioGagal,
    );
    clientGagal.dio.options.connectTimeout = null;
    clientGagal.dio.options.receiveTimeout = null;
    expect(
      await wajibUpdateDariServer(VersiApi(clientGagal), 'customer', '0.1.0'),
      isFalse,
    );
  });
}

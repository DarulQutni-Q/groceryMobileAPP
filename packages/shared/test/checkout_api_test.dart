import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'address CRUD and payment polling preserve authenticated client contract',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null,
          );
      final calls = <String>[];
      const address = {
        'id': 'a1',
        'label': 'Rumah',
        'nama_penerima': 'Pembeli',
        'no_hp': '081234567890',
        'alamat_lengkap': 'Jalan Melati',
        'patokan': null,
        'is_utama': true,
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = TestAdapter((request) async {
        calls.add('${request.method} ${request.path}');
        if (request.path.endsWith('/status')) {
          return jsonBody({
            'id': 'b1',
            'pesanan_id': 'o1',
            'metode': 'cod',
            'status': 'pending',
            'jumlah': 11000,
            'payment_url': null,
            'perlu_rekonsiliasi': false,
          }, 200);
        }
        if (request.method == 'DELETE') return jsonBody({}, 204);
        return jsonBody(request.method == 'GET' ? [address] : address, 200);
      });
      final client = ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      );
      final api = AlamatApi(client);
      expect((await api.list()).single.isUtama, isTrue);
      expect((await api.create(address)).namaPenerima, 'Pembeli');
      await api.update('a1', address);
      await api.jadikanUtama('a1');
      await api.delete('a1');
      final payment = await CheckoutApi(client).cekStatusBayar('b1');
      expect(payment.status, 'pending');
      expect(payment.perluRekonsiliasi, isFalse);
      expect(calls, [
        'GET /alamat',
        'POST /alamat',
        'PUT /alamat/a1',
        'PATCH /alamat/a1/jadikan-utama',
        'DELETE /alamat/a1',
        'GET /pembayaran/b1/status',
      ]);
    },
  );
}

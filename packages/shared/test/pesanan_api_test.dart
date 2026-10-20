import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

Map<String, dynamic> sampleOrder() => {
  'id': 'o1',
  'kode': 'DG-12345',
  'toko_id': 't1',
  'customer_id': null,
  'status': 'baru',
  'alamat_kirim': 'Jalan Uji',
  'catatan': null,
  'metode_kirim': 'Instant',
  'slot_waktu': 'Hari ini 15.00-17.00',
  'subtotal': 30000,
  'diskon': 1000,
  'ongkir': 5000,
  'biaya_layanan': 500,
  'total': 34500,
  'tolak_alasan': null,
  'nama_pembeli': null,
  'telepon_pembeli': null,
  'created_at': '2026-10-20T08:00:00Z',
  'updated_at': '2026-10-20T08:00:00Z',
  'server_time': '2026-10-20T08:00:01Z',
  'undo_until': null,
  'items': [
    {
      'produk_id': null,
      'nama_snapshot': 'Beras Uji',
      'harga_snapshot': 15000,
      'qty': 2,
    },
  ],
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
  test(
    'order API preserves snapshots, tab filter and transition payloads',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      final calls = <String>[];
      dio.httpClientAdapter = TestAdapter((request) async {
        calls.add('${request.method} ${request.path}');
        if (request.path == '/pesanan') {
          expect(request.queryParameters, {'status': 'diproses'});
          return jsonBody([sampleOrder()], 200);
        }
        if (request.path.endsWith('/tolak')) {
          expect(request.data, {'alasan': 'Stok Habis'});
        }
        if (request.path.endsWith('/status')) {
          expect(request.data, {'status': 'dikemas'});
        }
        return jsonBody(sampleOrder(), 200);
      });
      final api = PesananApi(
        ApiClient(
          baseUrl: dio.options.baseUrl,
          dio: dio,
          storage: SecureStorage(),
        ),
      );
      final items = await api.list(status: 'diproses');
      expect(items.single.kode, 'DG-12345');
      expect(items.single.items.single.produkId, isNull);
      expect(items.single.items.single.hargaSnapshot, 15000);
      expect(items.single.total, 34500);
      expect(items.single.createdAt.isUtc, isTrue);
      expect(items.single.updatedAt, DateTime.utc(2026, 10, 20, 8));
      expect(items.single.namaPembeli, isNull);
      await api.detail('o1');
      await api.terima('o1');
      await api.tolak('o1', 'Stok Habis');
      await api.updateStatus('o1', 'dikemas');
      await api.urungkan('o1');
      expect(calls, [
        'GET /pesanan',
        'GET /pesanan/o1',
        'PATCH /pesanan/o1/terima',
        'PATCH /pesanan/o1/tolak',
        'PATCH /pesanan/o1/status',
        'PATCH /pesanan/o1/urungkan',
      ]);
    },
  );
}

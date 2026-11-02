import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/lacak_kurir_page.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Map<String, dynamic> _orderJson() => {
  'id': 'order-1',
  'kode': 'GM-1001',
  'status': 'diantar',
  'alamat_kirim': 'Jalan Melati 1',
  'metode_kirim': 'Instant',
  'slot_waktu': '',
  'subtotal': 50000,
  'diskon': 0,
  'ongkir': 0,
  'biaya_layanan': 1000,
  'total': 51000,
  'items': [],
  'created_at': '2026-11-02T10:00:00Z',
  'customer_id': 'u1',
  'toko_id': 't1',
};

Map<String, dynamic> _riwayat(String status, String waktu) => {
  'id': 'r-$status',
  'pesanan_id': 'order-1',
  'status': status,
  'keterangan': null,
  'created_at': waktu,
};

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  testWidgets('halaman lacak menampilkan riwayat status dari backend', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((request) async {
      if (request.path == '/pesanan') {
        return _json({
          'data': [_orderJson()],
          'meta': {'total': 1, 'page': 1, 'per_page': 20},
        });
      }
      if (request.path == '/pesanan/order-1/riwayat') {
        return _json([
          _riwayat('baru', '2026-11-02T10:00:00Z'),
          _riwayat('diproses', '2026-11-02T10:05:00Z'),
          _riwayat('diantar', '2026-11-02T10:30:00Z'),
        ]);
      }
      return _json({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: SecureStorage(),
      dio: dio,
    );
    client.dio.options.connectTimeout = null;
    client.dio.options.receiveTimeout = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pesananApiProvider.overrideWith((ref) => PesananApi(client)),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const LacakKurirPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('GM-1001'), findsOneWidget);
    expect(find.text('Riwayat Status'), findsOneWidget);
    expect(find.text('Diantar'), findsWidgets);
    expect(find.textContaining('2 Nov 2026'), findsWidgets);
  });
}

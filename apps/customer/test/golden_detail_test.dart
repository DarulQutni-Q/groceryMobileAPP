import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/detail_pesanan_page.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (requestPath(options) == '/pesanan/o-baru') {
      return _json({
        'id': 'o-baru',
        'kode': 'GM-2001',
        'status': 'diantar',
        'alamat_kirim': 'Jl. Contoh No. 1',
        'metode_kirim': 'Instant',
        'slot_waktu': '15 menit',
        'subtotal': 30000,
        'diskon': 0,
        'ongkir': 0,
        'biaya_layanan': 1000,
        'total': 31000,
        'items': [
          {
            'produk_id': 'p-beras',
            'nama_snapshot': 'Beras Premium 5kg',
            'harga_snapshot': 25000,
            'qty': 1,
          },
        ],
        'created_at': '2026-10-31T08:00:00Z',
      });
    }
    if (requestPath(options) == '/pesanan/o-baru/riwayat') {
      return _json([
        {
          'id': 'r-2',
          'pesanan_id': 'o-baru',
          'status': 'diantar',
          'created_at': '2026-10-31T09:00:00Z',
        },
        {
          'id': 'r-1',
          'pesanan_id': 'o-baru',
          'status': 'baru',
          'created_at': '2026-10-31T08:00:00Z',
        },
      ]);
    }
    return _json({'detail': 'Tidak ditemukan'}, 404);
  }

  String requestPath(RequestOptions options) => options.path;

  ResponseBody _json(Object data, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
  });

  testWidgets('golden detail pesanan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter();
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
          home: const DetailPesananPage(pesananId: 'o-baru'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pesanan GM-2001'), findsOneWidget);
    expect(find.text('Beras Premium 5kg x1'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/detail_pesanan.png'),
    );
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/application/promo_harga_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/kilat_murah_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/tebus_murah_page.dart';
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

Map<String, dynamic> _promo(String jenis, String produk) => {
  'id': 'pr-$jenis',
  'toko_id': 'toko-1',
  'toko_nama': 'Toko Uji',
  'produk_id': 'p-$jenis',
  'judul': jenis == 'tebus' ? 'Tebus Biskuit 5rb' : 'Kilat Kerupuk 1rb',
  'jenis': jenis,
  'harga_promo': jenis == 'tebus' ? 5000 : 1000,
  'min_belanja': 0,
  'aktif': true,
  'berakhir_at': jenis == 'kilat' ? '2026-11-03T23:59:00Z' : null,
  'created_at': '2026-11-02T00:00:00Z',
  'produk': {
    'id': 'p-$jenis',
    'toko_id': 'toko-1',
    'nama': produk,
    'harga': jenis == 'tebus' ? 20000 : 5000,
    'foto_url': null,
    'satuan': 'pcs',
    'kategori': 'Camilan',
    'stok': 10,
    'is_tersedia': true,
  },
};

Future<void> _pump(WidgetTester tester, Widget page) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    if (request.path == '/promo/aktif') {
      return _json([_promo('tebus', 'Biskuit'), _promo('kilat', 'Kerupuk')]);
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
        promoHargaApiProvider.overrideWith((ref) => PromoHargaApi(client)),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

  testWidgets('halaman tebus hanya menampilkan promo tebus dengan harga tebus', (
    tester,
  ) async {
    await _pump(tester, const TebusMurahPage());
    expect(find.text('Biskuit'), findsOneWidget);
    expect(find.text('Kerupuk'), findsNothing);
    expect(find.text('Rp 5.000'), findsOneWidget);
    expect(find.text('-75%'), findsOneWidget);
  });

  testWidgets('halaman kilat menampilkan promo kilat dengan batas waktu', (
    tester,
  ) async {
    await _pump(tester, const KilatMurahPage());
    expect(find.text('Kerupuk'), findsOneWidget);
    expect(find.text('Biskuit'), findsNothing);
    expect(find.textContaining('Berakhir'), findsOneWidget);
    expect(find.text('Rp 1.000'), findsOneWidget);
  });
}

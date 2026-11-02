import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pesanan_page.dart';
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

Map<String, dynamic> _orderJson(String status) => {
  'id': 'o-baru',
  'kode': 'GM-2001',
  'status': status,
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
};

Future<void> _pump(
  WidgetTester tester, {
  required String statusAwal,
  required List<String> patchCalls,
}) async {
  var cancelled = false;
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    if (request.path == '/pesanan' && request.method == 'GET') {
      return _json({
        'data': [_orderJson(cancelled ? 'dibatalkan' : statusAwal)],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      });
    }
    if (request.path == '/pesanan/o-baru/batalkan' &&
        request.method == 'PATCH') {
      patchCalls.add(request.path);
      cancelled = true;
      return _json(_orderJson('dibatalkan'));
    }
    return _json({'detail': 'Tidak ditemukan'}, 404);
  });
  final client = ApiClient(
    baseUrl: dio.options.baseUrl,
    storage: SecureStorage(),
    dio: dio,
  );
  // ApiClient memasang timeout 15 detik; Dio mengubahnya jadi Timer yang
  // menggantung di fake_async widget test. Matikan untuk test ini saja.
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
        home: const Scaffold(body: SafeArea(child: PesananPage())),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  // Flush timer internal Dio (nol detik) sebelum teardown test.
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final saved = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'read') return saved[key];
            if (call.method == 'write') saved[key] = args['value'] as String;
            if (call.method == 'delete') saved.remove(key);
            return null;
          },
        );
  });

  testWidgets('tombol batalkan membatalkan setelah konfirmasi', (tester) async {
    final patchCalls = <String>[];
    await _pump(tester, statusAwal: 'baru', patchCalls: patchCalls);
    expect(find.text('Batalkan pesanan'), findsOneWidget);

    await tester.tap(find.text('Batalkan pesanan'));
await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan GM-2001?'), findsOneWidget);
    expect(
      find.textContaining('pengembalian dana diproses manual oleh toko'),
      findsOneWidget,
    );

    await tester.tap(find.text('Batalkan'));
await tester.pumpAndSettle();
    expect(patchCalls, ['/pesanan/o-baru/batalkan']);
    expect(find.text('Pesanan GM-2001 dibatalkan.'), findsOneWidget);
    expect(find.text('Batalkan pesanan'), findsNothing);
  });

  testWidgets('tombol kembali menutup dialog tanpa memanggil API', (
    tester,
  ) async {
    final patchCalls = <String>[];
    await _pump(tester, statusAwal: 'diproses', patchCalls: patchCalls);
    await tester.tap(find.text('Batalkan pesanan'));
await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali'));
await tester.pumpAndSettle();
    expect(patchCalls, isEmpty);
    expect(find.text('Batalkan pesanan'), findsOneWidget);
  });

  testWidgets('tombol batalkan juga muncul untuk pesanan diantar', (
    tester,
  ) async {
    final patchCalls = <String>[];
    await _pump(tester, statusAwal: 'diantar', patchCalls: patchCalls);
    expect(find.text('Batalkan pesanan'), findsOneWidget);

    await tester.tap(find.text('Batalkan pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan GM-2001?'), findsOneWidget);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(patchCalls, ['/pesanan/o-baru/batalkan']);
    expect(find.text('Pesanan GM-2001 dibatalkan.'), findsOneWidget);
    expect(find.text('Batalkan pesanan'), findsNothing);
  });
}

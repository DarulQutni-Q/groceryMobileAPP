import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/detail_pesanan_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/notifications_page.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_state_test.dart' show AuthFixture, CustomerAdapter, response;
import 'golden_test.dart' show loadTestFonts;

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {Headers.contentTypeHeader: ['application/json']},
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

List<Map<String, dynamic>> _riwayatJson() => [
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
    ];

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

  testWidgets('detail pesanan menampilkan isi, biaya, dan riwayat',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((request) async {
      if (request.path == '/pesanan/o-baru' && request.method == 'GET') {
        return _json(_orderJson('diantar'));
      }
      if (request.path == '/pesanan/o-baru/riwayat') {
        return _json(_riwayatJson());
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
          home: const DetailPesananPage(pesananId: 'o-baru'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pesanan GM-2001'), findsOneWidget);
    expect(find.text('Diantar'), findsNWidgets(2));
    expect(find.text('Beras Premium 5kg x1'), findsOneWidget);
    expect(find.text('Rp 31.000'), findsOneWidget);
    expect(find.text('Riwayat Status'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Batalkan pesanan'),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan'), findsOneWidget);
  });

  testWidgets('detail pesanan: batalkan mengubah status dan tombol hilang',
      (tester) async {
    var cancelled = false;
    final patchCalls = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((request) async {
      if (request.path == '/pesanan/o-baru' && request.method == 'GET') {
        return _json(_orderJson(cancelled ? 'dibatalkan' : 'diantar'));
      }
      if (request.path == '/pesanan/o-baru/riwayat') {
        return _json(_riwayatJson());
      }
      if (request.path == '/pesanan/o-baru/batalkan' &&
          request.method == 'PATCH') {
        patchCalls.add(request.path);
        cancelled = true;
        return _json(_orderJson('dibatalkan'));
      }
      if (request.path == '/pesanan' && request.method == 'GET') {
        return _json({'data': [], 'meta': {}});
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
          home: const DetailPesananPage(pesananId: 'o-baru'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Batalkan pesanan'),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan GM-2001?'), findsOneWidget);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(patchCalls, ['/pesanan/o-baru/batalkan']);
    expect(find.text('Pesanan GM-2001 dibatalkan.'), findsOneWidget);
    expect(find.text('Batalkan pesanan'), findsNothing);
  });

  testWidgets('tap notifikasi membuka detail pesanannya', (tester) async {
    final fixture = AuthFixture()..installStorage();
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      if (request.path == '/notifikasi' && request.method == 'GET') {
        return response({
          'data': [
            {
              'id': 'n-1',
              'judul': 'Pesanan GM-2001',
              'isi': 'Status pesananmu kini: Diantar',
              'pesanan_id': 'o-baru',
              'dibaca': false,
              'created_at': '2026-11-02T10:00:00Z',
            },
          ],
          'belum_dibaca': 1,
        });
      }
      if (request.path == '/notifikasi/n-1/baca') {
        return response({'dibaca': true});
      }
      if (request.path == '/pesanan/o-baru' && request.method == 'GET') {
        return response(_orderJson('diantar'));
      }
      if (request.path == '/pesanan/o-baru/riwayat') {
        return response(_riwayatJson());
      }
      return response({}, 404);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pesanan GM-2001'));
    await tester.pumpAndSettle();
    expect(find.text('Beras Premium 5kg x1'), findsOneWidget);
    expect(find.text('Riwayat Status'), findsOneWidget);
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/features/store/application/promo_provider.dart';
import 'package:seller/features/store/presentation/promo_page.dart';

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

Map<String, dynamic> _promo(String id, bool aktif) => {
  'id': id,
  'toko_id': 'toko-1',
  'toko_nama': 'Toko Uji',
  'produk_id': 'p1',
  'judul': 'Tebus Biskuit 5rb',
  'jenis': 'tebus',
  'harga_promo': 5000,
  'min_belanja': 0,
  'aktif': aktif,
  'berakhir_at': null,
  'created_at': '2026-11-02T00:00:00Z',
  'produk': {
    'id': 'p1',
    'toko_id': 'toko-1',
    'nama': 'Biskuit',
    'harga': 20000,
    'foto_url': null,
    'satuan': 'pcs',
    'kategori': 'Camilan',
    'stok': 10,
    'is_tersedia': true,
  },
};

Future<void> _pump(WidgetTester tester, List<String> calls) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    calls.add('${request.method} ${request.path}');
    if (request.path == '/promo' && request.method == 'GET') {
      return _json([_promo('pr1', true)]);
    }
    if (request.path == '/promo/pr1' && request.method == 'PATCH') {
      return _json(_promo('pr1', false));
    }
    if (request.path == '/promo/pr1' && request.method == 'DELETE') {
      return _json({}, 204);
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
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PromoPage(userId: 'u1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  testWidgets('daftar promo tampil dan toggle memanggil PATCH', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    expect(calls, contains('GET /promo'));
    expect(find.text('Tebus Biskuit 5rb • tebus'), findsOneWidget);
    expect(find.textContaining('Rp 20000 → Rp 5000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('promo-aktif-pr1')));
    await tester.pumpAndSettle();
    expect(calls, contains('PATCH /promo/pr1'));
  });

  testWidgets('hapus promo meminta konfirmasi lalu memanggil DELETE', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    await tester.tap(find.byKey(const Key('promo-hapus-pr1')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus promo?'), findsOneWidget);
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(calls, contains('DELETE /promo/pr1'));
  });
}

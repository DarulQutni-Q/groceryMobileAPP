import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/features/store/application/voucher_provider.dart';
import 'package:seller/features/store/presentation/voucher_page.dart';

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

Map<String, dynamic> _voucher(String id, String kode, bool aktif) => {
  'id': id,
  'toko_id': 'toko-1',
  'kode': kode,
  'judul': 'Judul $kode',
  'jenis': 'persen',
  'persen': 10,
  'cap': 5000,
  'min_belanja': 0,
  'max_ongkir': 0,
  'aktif': aktif,
  'created_at': '2026-11-02T00:00:00Z',
};

Future<void> _pump(WidgetTester tester, List<String> calls) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    calls.add('${request.method} ${request.path}');
    if (request.path == '/voucher' && request.method == 'GET') {
      return _json([_voucher('v1', 'HEMAT10', true)]);
    }
    if (request.path == '/voucher/v1' && request.method == 'PATCH') {
      return _json(_voucher('v1', 'HEMAT10', false));
    }
    if (request.path == '/voucher/v1' && request.method == 'DELETE') {
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
        voucherApiProvider.overrideWith((ref) => VoucherApi(client)),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: VoucherPage(),
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

  testWidgets('daftar voucher tampil dan toggle memanggil PATCH', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    expect(calls, contains('GET /voucher'));
    expect(find.text('HEMAT10 • Judul HEMAT10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voucher-aktif-v1')));
    await tester.pumpAndSettle();
    expect(calls, contains('PATCH /voucher/v1'));
  });

  testWidgets('hapus voucher meminta konfirmasi lalu memanggil DELETE', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    await tester.tap(find.byKey(const Key('voucher-hapus-v1')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus voucher?'), findsOneWidget);
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(calls, contains('DELETE /voucher/v1'));
  });
}

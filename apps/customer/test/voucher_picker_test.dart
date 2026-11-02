import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/checkout/application/voucher_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/voucher_picker_page.dart';
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

Map<String, dynamic> _voucher(
  String id,
  String kode,
  String judul,
  String jenis, {
  int persen = 0,
  int cap = 0,
  int minBelanja = 0,
  int maxOngkir = 0,
}) => {
  'id': id,
  'toko_id': 'toko-1',
  'kode': kode,
  'judul': judul,
  'jenis': jenis,
  'persen': persen,
  'cap': cap,
  'min_belanja': minBelanja,
  'max_ongkir': maxOngkir,
  'aktif': true,
  'created_at': '2026-11-02T00:00:00Z',
};

Future<void> _pump(WidgetTester tester, List<String> calls) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    calls.add('${request.method} ${request.path}');
    if (request.path == '/voucher/toko/toko-1') {
      return _json([
        _voucher('v1', 'HEMAT10', 'Hemat 10%', 'persen',
            persen: 10, cap: 5000),
        _voucher('v2', 'BESAR', 'Min besar', 'persen',
            persen: 30, cap: 25000, minBelanja: 75000),
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
        voucherApiProvider.overrideWith((ref) => VoucherApi(client)),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: const VoucherPickerPage(
          tokoId: 'toko-1',
          subtotal: 34000,
          ongkir: 0,
        ),
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
          (call) async => null,
        );
  });

  testWidgets('pemilih menampilkan voucher backend dan tanpa voucher', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    expect(calls, contains('GET /voucher/toko/toko-1'));
    expect(find.text('Hemat 10%'), findsOneWidget);
    expect(find.text('Min besar'), findsOneWidget);
    expect(find.text('Tanpa voucher'), findsOneWidget);
    expect(find.text('Hemat Rp 3.400'), findsOneWidget);
    expect(find.text('Min. belanja Rp 75.000 belum tercapai'), findsOneWidget);
  });

  testWidgets('mengetuk voucher kembali dengan voucher itu', (tester) async {
    final calls = <String>[];
    Voucher? hasil;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voucherApiProvider.overrideWith((ref) {
            final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
            dio.httpClientAdapter = _Adapter((request) async {
              if (request.path == '/voucher/toko/toko-1') {
                return _json([
                  _voucher('v1', 'HEMAT10', 'Hemat 10%', 'persen',
                      persen: 10, cap: 5000),
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
            return VoucherApi(client);
          }),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                hasil = await Navigator.push<Voucher>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoucherPickerPage(
                      tokoId: 'toko-1',
                      subtotal: 34000,
                      ongkir: 0,
                    ),
                  ),
                );
              },
              child: const Text('Buka pemilih'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka pemilih'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hemat 10%'));
    await tester.pumpAndSettle();
    expect(hasil?.kode, 'HEMAT10');
    expect(find.text('Buka pemilih'), findsOneWidget);
  });

  testWidgets('voucher di bawah minimal belanja tidak bisa dipilih', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls);
    await tester.tap(find.text('Min besar'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Voucher'), findsOneWidget);
  });
}

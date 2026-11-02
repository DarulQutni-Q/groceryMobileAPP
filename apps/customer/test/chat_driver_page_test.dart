import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/application/chat_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
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

Map<String, dynamic> _pesan(String peran, String isi) => {
  'id': 'm-$peran-$isi',
  'pesanan_id': 'order-1',
  'pengirim_id': 'u-$peran',
  'pengirim_peran': peran,
  'isi': isi,
  'created_at': '2026-11-02T10:00:00Z',
};

Pesanan _order() => Pesanan(
  id: 'order-1',
  kode: 'GM-1001',
  status: 'diantar',
  alamatKirim: 'Jalan Melati 1',
  metodeKirim: 'Instant',
  slotWaktu: '',
  subtotal: 50000,
  diskon: 0,
  ongkir: 0,
  biayaLayanan: 1000,
  total: 51000,
  items: const [],
  createdAt: DateTime.utc(2026, 11, 2, 10),
);

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

  testWidgets('chat memuat riwayat backend dan kirim memanggil POST', (
    tester,
  ) async {
    final riwayat = [
      _pesan('toko', 'Pesanan sedang diantar ya.'),
      _pesan('customer', 'Baik, ditunggu.'),
    ];
    final calls = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((request) async {
      calls.add('${request.method} ${request.path}');
      if (request.path == '/chat/pesanan/order-1' &&
          request.method == 'GET') {
        return _json(riwayat);
      }
      if (request.path == '/chat/pesanan/order-1' &&
          request.method == 'POST') {
        final body = request.data as Map<String, dynamic>;
        riwayat.add(_pesan('customer', body['isi'] as String));
        return _json(riwayat.last, 201);
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
          chatApiProvider.overrideWith((ref) => ChatApi(client)),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: ChatDriverPage(order: _order()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pesanan sedang diantar ya.'), findsOneWidget);
    expect(find.text('Baik, ditunggu.'), findsOneWidget);
    expect(
      find.text('Pesanan telah diserahkan ke Kurir Toko'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('chat-input')), 'Terima kasih');
    await tester.tap(find.byKey(const Key('chat-kirim')));
    await tester.pumpAndSettle();
    expect(calls, contains('POST /chat/pesanan/order-1'));
    expect(find.text('Terima kasih'), findsOneWidget);
  });
}

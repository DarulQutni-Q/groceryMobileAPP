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
import 'package:gardenmart_customer/features/checkout/presentation/struk_page.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;
import 'pesanan_fixture.dart';

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
  headers: {Headers.contentTypeHeader: ['application/json']},
);

/// Halaman chat dengan API chat stub (GET kosong, POST menggemakan pesan).
Future<void> _pumpChat(
  WidgetTester tester, {
  Pesanan? order,
  List<String>? calls,
}) async {
  final riwayat = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    calls?.add('${request.method} ${request.path}');
    if (request.method == 'GET') return _json(riwayat);
    if (request.method == 'POST') {
      final body = request.data as Map<String, dynamic>;
      final pesan = {
        'id': 'm-baru',
        'pesanan_id': order?.id ?? 'order-1',
        'pengirim_id': 'u-customer',
        'pengirim_peran': 'customer',
        'isi': body['isi'],
        'created_at': '2026-11-02T10:00:00Z',
      };
      riwayat.add(pesan);
      return _json(pesan, 201);
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
      overrides: [chatApiProvider.overrideWith((ref) => ChatApi(client))],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: ChatDriverPage(order: order),
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

  testWidgets('header generik + kartu pesanan asli, bukan data referensi', (
    tester,
  ) async {
    final order = pesananFixture().first; // GM-1001, diantar, Rp 67.600
    await _pumpChat(tester, order: order);

    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.text('Sedang mengantar pesananmu'), findsOneWidget);
    expect(find.text('Pesanan #GM-1001'), findsOneWidget);
    expect(find.text('Diantar • Rp 67.600'), findsOneWidget);
    // Data referensi Figma tidak boleh muncul sebagai data.
    expect(find.textContaining('Pak Budi'), findsNothing);
    expect(find.textContaining('BK 4122'), findsNothing);
    expect(find.textContaining('GM-8921'), findsNothing);
    // Pesan sistem hanya untuk pesanan yang sedang diantar.
    expect(
      find.text('Pesanan telah diserahkan ke Kurir Toko'),
      findsOneWidget,
    );
    expect(find.text('Hari Ini'), findsOneWidget);
  });

  testWidgets('pesan sistem tidak tampil kalau pesanan belum diantar', (
    tester,
  ) async {
    final order = pesananFixture()[1]; // GM-0998, selesai
    await _pumpChat(tester, order: order);

    expect(find.text('Pesanan #GM-0998'), findsOneWidget);
    expect(
      find.text('Pesanan telah diserahkan ke Kurir Toko'),
      findsNothing,
    );
  });

  testWidgets('tanpa pesanan: kartu disembunyikan, chat tetap jalan', (
    tester,
  ) async {
    await _pumpChat(tester);

    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.textContaining('Pesanan #'), findsNothing);
    expect(
      find.textContaining('Belum ada pesan untuk pesanan ini.'),
      findsOneWidget,
    );
  });

  testWidgets('tombol kembali kembali ke layar sebelumnya', (tester) async {
    final order = pesananFixture().first;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((_) async => _json([]));
    final client = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: SecureStorage(),
      dio: dio,
    );
    client.dio.options.connectTimeout = null;
    client.dio.options.receiveTimeout = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatApiProvider.overrideWith((ref) => ChatApi(client))],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatDriverPage(order: order),
                    ),
                  ),
                  child: const Text('Buka Chat'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Kurir Toko'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Buka Chat'), findsOneWidget);
    expect(find.text('Kurir Toko'), findsNothing);
  });

  testWidgets('ikon telepon menampilkan dialog jujur tanpa nomor', (
    tester,
  ) async {
    final order = pesananFixture().first;
    await _pumpChat(tester, order: order);

    await tester.tap(find.byIcon(Icons.phone));
    await tester.pumpAndSettle();
    expect(find.text('Telepon Kurir'), findsOneWidget);
    expect(
      find.textContaining('Nomor telepon kurir belum tersedia'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Telepon Kurir'), findsNothing);
  });

  testWidgets('Lihat Detail membuka struk pesanan yang sama', (tester) async {
    final order = pesananFixture().first;
    await _pumpChat(tester, order: order);

    await tester.tap(find.text('Lihat Detail ›'));
    await tester.pumpAndSettle();
    expect(find.byType(StrukPage), findsOneWidget);
    expect(find.textContaining('GM-1001'), findsWidgets);
  });

  testWidgets('kirim pesan menambah bubble, field dibersihkan', (
    tester,
  ) async {
    final order = pesananFixture().first;
    final calls = <String>[];
    await _pumpChat(tester, order: order, calls: calls);

    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Tolong titip di teras ya',
    );
    await tester.tap(find.byKey(const Key('chat-kirim')));
    await tester.pumpAndSettle();

    expect(calls, contains('POST /chat/pesanan/${order.id}'));
    expect(find.text('Tolong titip di teras ya'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(field.controller!.text, isEmpty);
    expect(find.textContaining('Belum ada pesan'), findsNothing);
  });

  testWidgets('kirim kosong diblokir', (tester) async {
    final order = pesananFixture().first;
    final calls = <String>[];
    await _pumpChat(tester, order: order, calls: calls);

    await tester.enterText(find.byKey(const Key('chat-input')), '   ');
    await tester.tap(find.byKey(const Key('chat-kirim')));
    await tester.pumpAndSettle();

    expect(calls.where((c) => c.startsWith('POST')), isEmpty);
    expect(find.textContaining('Belum ada pesan'), findsOneWidget);
  });
}

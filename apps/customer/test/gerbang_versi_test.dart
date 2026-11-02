import 'dart:convert';
import 'dart:typed_data';

import 'package:gardenmart_customer/features/auth/presentation/gerbang_versi.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

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

Future<void> _pump(WidgetTester tester, bool wajib) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    if (request.path == '/versi-minimum') {
      return _json({
        'aplikasi': 'customer',
        'versi_saat_ini': '0.1.0',
        'versi_minimum': '0.2.0',
        'wajib_update': wajib,
      });
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GerbangVersi(
          aplikasi: 'customer',
          versiSaatIni: '0.1.0',
          api: VersiApi(client),
          child: const Text('Aplikasi jalan'),
        ),
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

  testWidgets('wajib update menampilkan layar blokir, bukan aplikasi', (
    tester,
  ) async {
    await _pump(tester, true);
    expect(find.text('Versi aplikasi sudah kedaluwarsa'), findsOneWidget);
    expect(find.text('Aplikasi jalan'), findsNothing);
  });

  testWidgets('tidak wajib update menampilkan aplikasi', (tester) async {
    await _pump(tester, false);
    expect(find.text('Aplikasi jalan'), findsOneWidget);
    expect(find.text('Versi aplikasi sudah kedaluwarsa'), findsNothing);
  });
}

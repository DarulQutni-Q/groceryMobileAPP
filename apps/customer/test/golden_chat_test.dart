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
import 'pesanan_fixture.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(<Map<String, dynamic>>[]),
        200,
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

  testWidgets('golden chat driver', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Pesanan fixture diantar (GM-1001, Rp 67.600): golden memverifikasi
    // layout lengkap dengan kartu pesanan dan pesan sistem.
    final order = pesananFixture().first;
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
        overrides: [chatApiProvider.overrideWith((ref) => ChatApi(client))],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: ChatDriverPage(order: order),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.text('Pesanan #GM-1001'), findsOneWidget);
    expect(find.text('Diantar • Rp 67.600'), findsOneWidget);
    expect(find.text('Pesanan telah diserahkan ke Kurir Toko'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chat_driver.png'),
    );
  });
}

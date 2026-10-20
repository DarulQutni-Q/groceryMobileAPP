import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/core/network.dart';
import 'package:seller/core/seller_theme.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/store/presentation/seller_shell.dart';

import 'support/laporan_fixture.dart';

class PolishFixture extends LaporanFixture {
  Completer<void>? storeGate;
  int sent = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    sent++;
    if (request.method == 'GET' &&
        ['/toko/me', '/produk'].contains(request.path)) {
      await storeGate?.future;
    }
    return super.fetch(request, stream, cancelFuture);
  }
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  Future<void> open(
    WidgetTester tester,
    PolishFixture fixture, {
    Future<bool> Function()? check,
    Stream<bool>? changes,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final connection = check ?? () async => true;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = fixture;
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      dio: dio,
      storage: SecureStorage(),
    );
    configureSellerNetwork(api, connection);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          apiBaseUrlProvider.overrideWithValue(dio.options.baseUrl),
          connectionCheckProvider.overrideWithValue(connection),
          connectionStateProvider.overrideWith((ref) async* {
            yield await connection();
            if (changes != null) yield* changes;
          }),
        ],
        child: MaterialApp(
          theme: sellerTheme(),
          home: const SellerShell(
            user: User(
              id: 'u1',
              nama: 'Pemilik Uji',
              email: 'uji@example.com',
              role: 'seller',
              namaToko: 'Toko Uji',
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('home shows offline and retry loads data after reconnecting', (
    tester,
  ) async {
    var connected = true;
    final changes = StreamController<bool>.broadcast();
    addTearDown(changes.close);
    final fixture = PolishFixture();
    await open(
      tester,
      fixture,
      check: () async => connected,
      changes: changes.stream,
    );
    expect(find.textContaining('Selamat Pagi'), findsOneWidget);
    connected = false;
    changes.add(false);
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.text('Belum bisa memuat data'), findsOneWidget);
    final sent = fixture.sent;
    await tester.scrollUntilVisible(find.text('Coba lagi'), 160);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(fixture.sent, sent);
    fixture.profile['nama'] = 'Toko Pulih';
    connected = true;
    changes.add(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada koneksi internet'), findsNothing);
    expect(find.textContaining('Toko Pulih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store loading stops within three seconds and retry is usable', (
    tester,
  ) async {
    final pending = Completer<void>();
    final fixture = PolishFixture()..storeGate = pending;
    await open(tester, fixture, settle: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Coba lagi'), findsOneWidget);
    pending.complete();
    fixture.storeGate = null;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Selamat Pagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty order tabs have an action and reports open from navigation',
    (tester) async {
      final fixture = PolishFixture()..orders.clear();
      await open(tester, fixture);
      await tester.tap(find.byKey(const Key('nav-pesanan')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Perbarui Pesanan'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perbarui Pesanan'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada pesanan baru'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-laporan')));
      await tester.pumpAndSettle();
      expect(find.text('Total Penjualan 7 hari'), findsOneWidget);
      expect(find.text('Tahap A4'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

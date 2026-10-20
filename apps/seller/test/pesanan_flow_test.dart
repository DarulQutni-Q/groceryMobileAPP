import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/core/seller_theme.dart';
import 'package:seller/core/network.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/store/presentation/seller_shell.dart';

import 'support/pesanan_fixture.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  Future<void> open(WidgetTester tester, {PesananFixture? fixture}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = fixture ?? PesananFixture();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionStateProvider.overrideWith((ref) => Stream.value(true)),
          apiBaseUrlProvider.overrideWithValue(dio.options.baseUrl),
          apiClientProvider.overrideWithValue(
            ApiClient(
              baseUrl: dio.options.baseUrl,
              dio: dio,
              storage: SecureStorage(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: sellerTheme(),
          home: const SellerShell(
            user: User(
              id: 'u1',
              nama: 'Pemilik',
              email: 'uji@example.com',
              role: 'seller',
              namaToko: 'Toko Uji',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-pesanan')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'orders show tabs counts and a detail with timeline and null customer',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('pesanan-count-diproses')), findsOneWidget);
      expect(find.text('DG-11111'), findsOneWidget);
      await tester.tap(find.text('DG-11111'));
      await tester.pumpAndSettle();
      for (final label in ['Diterima', 'Dikemas', 'Diantar', 'Tiba']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.byTooltip('Nomor telepon belum tersedia'), findsOneWidget);
      expect(find.text('Rp 34.500'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('acceptance shows confirmation and undo restores new status', (
    tester,
  ) async {
    final fixture = PesananFixture();
    await open(tester, fixture: fixture);
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terima Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Pesanan DG-11111 diterima'), findsOneWidget);
    expect(fixture.orders.first['status'], 'diproses');
    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(fixture.orders.first['status'], 'baru');
    expect(find.text('Terima Pesanan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('rejection requires a reason and moves order to completed tab', (
    tester,
  ) async {
    final fixture = PesananFixture();
    await open(tester, fixture: fixture);
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Kenapa pesanan ditolak?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('pesanan-reject-confirm')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pesanan-reject-reason')),
      'Produk rusak',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pesanan-reject-confirm')));
    await tester.pumpAndSettle();
    expect(fixture.orders.first['status'], 'ditolak');
    expect(fixture.orders.first['tolak_alasan'], 'Produk rusak');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pesanan-tab-selesai')));
    await tester.pumpAndSettle();
    expect(find.text('DG-11111'), findsOneWidget);
    expect(find.text('Ditolak'), findsWidgets);
  });
  testWidgets('retry recovers an order list error', (tester) async {
    final fixture = PesananFixture()..failList = true;
    await open(tester, fixture: fixture);
    expect(find.text('Pesanan belum dapat dimuat'), findsOneWidget);
    fixture.failList = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('DG-11111'), findsOneWidget);
  });

  testWidgets('accept confirmation does not wait for a slow list refresh', (
    tester,
  ) async {
    final fixture = PesananFixture();
    await open(tester, fixture: fixture);
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    final gate = Completer<void>();
    fixture.listGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.tap(find.text('Terima Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Pesanan DG-11111 diterima'), findsOneWidget);
    expect(gate.isCompleted, isFalse);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('pending undo is safe when sheet and detail are closed', (
    tester,
  ) async {
    final fixture = PesananFixture();
    await open(tester, fixture: fixture);
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terima Pesanan'));
    await tester.pumpAndSettle();
    final gate = Completer<void>();
    fixture.undoGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.tap(find.text('Urungkan'));
    await tester.pump();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail refresh reports offline error without throwing', (
    tester,
  ) async {
    final fixture = PesananFixture();
    await open(tester, fixture: fixture);
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    fixture.failDetail = true;
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator).last,
    );
    final check = expectLater(refresh.onRefresh(), completes);
    await tester.pumpAndSettle();
    await check;
    expect(find.text('Detail pesanan belum dapat dimuat'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejection remains usable with keyboard on a 320x568 phone', (
    tester,
  ) async {
    await open(tester);
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DG-11111'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak Pesanan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lainnya'));
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.ensureVisible(find.byKey(const Key('pesanan-reject-reason')));
    await tester.enterText(
      find.byKey(const Key('pesanan-reject-reason')),
      'Alasan uji',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/core/seller_theme.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/laporan/presentation/laporan_screen.dart';

import 'support/laporan_fixture.dart';

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
    LaporanFixture fixture, {
    VoidCallback? openOrders,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = fixture;
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      dio: dio,
      storage: SecureStorage(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          apiBaseUrlProvider.overrideWithValue(dio.options.baseUrl),
        ],
        child: MaterialApp(
          theme: sellerTheme(),
          home: Scaffold(
            body: LaporanScreen(
              userId: 'u1',
              namaToko: 'Toko Uji',
              openOrders: openOrders ?? () {},
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets(
    'report changes 7 to 30 days and shows five products with see all',
    (tester) async {
      final fixture = LaporanFixture();
      await open(tester, fixture);
      expect(find.text('Total Penjualan 7 hari'), findsOneWidget);
      expect(find.text('Rp 124.000'), findsOneWidget);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.length,
        7,
      );
      await tester.scrollUntilVisible(
        find.text('Lihat semua'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Beras 6'), findsNothing);
      await tester.tap(find.text('Lihat semua'));
      await tester.pumpAndSettle();
      expect(find.text('Segera hadir'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('laporan-range-30h')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('laporan-range-30h')));
      await tester.pumpAndSettle();
      expect(find.text('Total Penjualan 30 hari'), findsOneWidget);
      expect(find.text('Rp 248.000'), findsOneWidget);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.length,
        30,
      );
      expect(
        fixture.requests.any((r) => r.queryParameters['range'] == '30h'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty report offers the orders action', (tester) async {
    var opened = 0;
    await open(
      tester,
      LaporanFixture()..empty = true,
      openOrders: () => opened++,
    );
    expect(find.text('Belum ada data penjualan.'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    await tester.scrollUntilVisible(find.text('Lihat Pesanan'), 180);
    await tester.tap(find.text('Lihat Pesanan'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a sales bar keeps the rupiah tooltip visible', (
    tester,
  ) async {
    await open(tester, LaporanFixture());
    final chart = find.byType(BarChart);
    await tester.ensureVisible(chart);
    await tester.pumpAndSettle();
    final rect = tester.getRect(chart);
    await tester.tapAt(Offset(rect.right - rect.width / 14, rect.top + 75));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BarChart>(chart)
          .data
          .barGroups
          .last
          .showingTooltipIndicators,
      [0],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('report error has a red snackbar and retry recovers', (
    tester,
  ) async {
    final fixture = LaporanFixture()..fail = true;
    await open(tester, fixture);
    expect(find.text('Laporan belum dapat dimuat'), findsWidgets);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      const Color(0xFFB3261E),
    );
    fixture.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 124.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'report stops loading after three seconds and ignores late data',
    (tester) async {
      final pending = Completer<void>();
      final fixture = LaporanFixture()..gate = pending;
      await open(tester, fixture, settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Coba lagi'), findsOneWidget);
      pending.complete();
      fixture.gate = null;
      await tester.pumpAndSettle();
      expect(find.text('Rp 124.000'), findsNothing);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Rp 124.000'), findsOneWidget);
    },
  );

  testWidgets('late 7 day data cannot replace the selected 30 day report', (
    tester,
  ) async {
    final pending = Completer<void>();
    final fixture = LaporanFixture()
      ..gate = pending
      ..blockedRange = '7h';
    await open(tester, fixture, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('laporan-range-30h')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 248.000'), findsOneWidget);
    pending.complete();
    fixture.gate = null;
    await tester.pumpAndSettle();
    expect(find.text('Rp 124.000'), findsNothing);
    expect(find.text('Rp 248.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

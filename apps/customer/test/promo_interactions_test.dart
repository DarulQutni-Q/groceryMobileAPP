import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/garden_widgets.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_jsm_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/tebus_murah_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_state_test.dart';
import 'golden_test.dart' show loadTestFonts;

Future<void> _bukaPromo(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(780, 1688);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: customerTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: authBackground,
        body: const SafeArea(child: PromoPage()),
        bottomNavigationBar: GardenBottomNav(index: 1, onSelect: (_) {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('promo: chip filter mempersempit daftar', (tester) async {
    await _bukaPromo(tester);
    await tester.tap(find.text('Gratis Ongkir'));
    await tester.pumpAndSettle();
    expect(find.text('Gratis Ongkir Instan s/d Rp 15.000'), findsOneWidget);
    expect(find.text('Diskon 30% Produk Segar (Fresh Mart)'), findsNothing);
    expect(find.text('Promo Mingguan'), findsNothing);

    await tester.tap(find.text('Diskon Belanja'));
    await tester.pumpAndSettle();
    expect(find.text('Diskon 30% Produk Segar (Fresh Mart)'), findsOneWidget);
    expect(find.text('Gratis Ongkir Instan s/d Rp 15.000'), findsNothing);
    expect(find.text('Promo Mingguan'), findsOneWidget);

    await tester.tap(find.text('Cashback'));
    await tester.pumpAndSettle();
    expect(find.text('Cashback 15.000 Poin Sembako'), findsOneWidget);
    expect(find.text('Diskon 30% Produk Segar (Fresh Mart)'), findsNothing);
    expect(find.text('Promo Mingguan'), findsNothing);

    await tester.tap(find.text('Semua Promo'));
    await tester.pumpAndSettle();
    expect(find.text('Promo Mingguan'), findsOneWidget);
    expect(find.text('Cashback 15.000 Poin Sembako'), findsOneWidget);
  });

  testWidgets('promo: klaim tersimpan lokal dan tampil di voucher saya', (
    tester,
  ) async {
    await _bukaPromo(tester);
    await tester.tap(find.text('Klaim').first);
    await tester.pumpAndSettle();
    // FREE ongkir sudah diklaim dari awal + 30% yang baru diklaim.
    expect(find.text('Sudah Klaim'), findsNWidgets(2));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('promo_klaim'),
      contains('Diskon 30% Produk Segar (Fresh Mart)'),
    );
    await tester.tap(find.text('Voucher saya'));
    await tester.pumpAndSettle();
    expect(find.text('Voucher Saya (2)'), findsOneWidget);
    expect(find.text('Cashback 15.000 Poin Sembako'), findsNothing);
    await tester.tap(find.text('Tampilkan Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Promo Mingguan'), findsOneWidget);
  });

  testWidgets('promo: voucher saya awal hanya menampilkan yang diklaim', (
    tester,
  ) async {
    await _bukaPromo(tester);
    await tester.tap(find.text('Voucher saya'));
    await tester.pumpAndSettle();
    expect(find.text('Voucher Saya (1)'), findsOneWidget);
    expect(find.text('Gratis Ongkir Instan s/d Rp 15.000'), findsOneWidget);
    expect(find.text('Diskon 30% Produk Segar (Fresh Mart)'), findsNothing);
  });

  testWidgets('promo: kartu mingguan JSM membuka halaman Promo JSM', (
    tester,
  ) async {
    final fixture = AuthFixture()..installStorage();
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      if (request.path == '/produk') {
        return response({
          'data': [],
          'meta': {'page': 1, 'per_page': 20, 'total': 0, 'total_pages': 1},
        });
      }
      if (request.path == '/kategori') return response(<String>[]);
      return response({'detail': 'Not Found'}, 404);
    });
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const Scaffold(
            backgroundColor: authBackground,
            body: SafeArea(child: PromoPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Katalog >'));
    await tester.pumpAndSettle();
    expect(find.byType(PromoJsmPage), findsOneWidget);
    expect(find.text('Promo JSM'), findsOneWidget);
    expect(find.text('Promo JSM Akhir Pekan'), findsOneWidget);
  });

  testWidgets('promo: kartu mingguan Tebus membuka halaman Tebus Murah', (
    tester,
  ) async {
    final fixture = AuthFixture()..installStorage();
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      if (request.path == '/produk') {
        return response({
          'data': [],
          'meta': {'page': 1, 'per_page': 20, 'total': 0, 'total_pages': 1},
        });
      }
      if (request.path == '/kategori') return response(<String>[]);
      return response({'detail': 'Not Found'}, 404);
    });
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const Scaffold(
            backgroundColor: authBackground,
            body: SafeArea(child: PromoPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Produk >'));
    await tester.pumpAndSettle();
    expect(find.byType(TebusMurahPage), findsOneWidget);
    expect(find.text('Tebus Murah'), findsOneWidget);
    expect(find.text('Tebus Murah Serba 5rb'), findsOneWidget);
  });
}

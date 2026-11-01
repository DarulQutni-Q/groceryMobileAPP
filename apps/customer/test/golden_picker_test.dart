import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/customer_shell.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_home_test.dart' show FakeAuthNotifier, FakeProdukNotifier;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  // Cerminan harness golden_home_test.openShell: jam dibekukan lewat
  // CustomerShell(now:) supaya SaleCountdown deterministik (05:17:30),
  // bukan jam live yang bikin golden berubah tiap detik.
  Future<void> openShell(WidgetTester tester) async {
    // IndexedStack membangun _AkunTab (offstage) yang membaca
    // profilLokalProvider -> SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    final fixture = AuthFixture()..installStorage();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          keranjangStorageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          tokoProvider.overrideWithValue(
            const AsyncValue.data(
              Halaman(
                data: [
                  Toko(
                    id: 't1',
                    nama: 'Indomaret Diponegoro 42',
                    alamat: 'Jl. Diponegoro No. 42',
                    telepon: '0618291122',
                    kategori: ['Sembako'],
                    radiusKm: 5,
                    status: 'buka',
                    metodeKirim: ['Kurir'],
                  ),
                ],
                page: 1,
                perPage: 10,
                total: 1,
                totalPages: 1,
              ),
            ),
          ),
          kategoriProvider.overrideWithValue(
            const AsyncValue.data(['Sembako', 'Minuman', 'Snack']),
          ),
          promoProvider.overrideWithValue(
            const AsyncValue.data([
              Promo(
                id: 'pr1',
                judul: 'INDOMARET POINKU • PROMO SPESIAL',
                deskripsi: 'Ada 4 voucher belanja diskon 50% siap kamu pakai.',
                labelTombol: 'Klaim Semua Voucher',
                isDemo: true,
              ),
            ]),
          ),
          produkProvider.overrideWith((ref) => FakeProdukNotifier()),
          // Tanpa override, Future readCheckout kadang melempar async
          // (WebSocket) dan badge jadi non-deterministik. Golden ini
          // mengunci kondisi tanpa checkout tertunda (tanpa badge).
          pendingCheckoutProvider.overrideWithValue(
            const AsyncValue.data(false),
          ),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: CustomerShell(now: () => DateTime(2026, 10, 26, 18, 41, 30)),
        ),
      ),
    );
    // Tanpa pumpAndSettle: SaleCountdown punya Timer.periodic yang bikin
    // settle tidak pernah selesai. Beberapa pump cukup karena semua
    // provider sudah dioverride dengan data langsung.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
  }

  testWidgets('golden pilih toko', (tester) async {
    await openShell(tester);
    final picker = find.byKey(const Key('store-picker'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    // Animasi sheet (~300ms) diselesaikan dengan pump manual, bukan
    // pumpAndSettle (tidak pernah settle karena Timer.periodic countdown).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pilih Toko'), findsOneWidget);
    expect(find.byKey(const Key('store-pick-t1')), findsOneWidget);
    // Subtitle alamat hanya ada di tile sheet (header hanya nama toko).
    expect(find.text('Jl. Diponegoro No. 42'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/picker_toko.png'),
    );
  });
}

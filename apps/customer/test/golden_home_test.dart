import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/customer_shell.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_test.dart' show loadTestFonts;

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier()
    : super(
        AuthApi(
          ApiClient(
            baseUrl: 'https://api.example.com',
            storage: SecureStorage(),
          ),
        ),
        SecureStorage(),
      ) {
    state = const AuthState(
      AuthStatus.authenticated,
      user: User(
        id: 'u1',
        nama: 'Darul Qutni',
        email: 'darul@example.com',
        role: 'customer',
        phone: '+6281288992122',
      ),
    );
  }
}

class FakeProdukNotifier extends ProdukNotifier {
  FakeProdukNotifier()
    : super(
        ProdukApi(
          ApiClient(
            baseUrl: 'https://api.example.com',
            storage: SecureStorage(),
          ),
        ),
      ) {
    state = const ProdukState(
      items: [
        Produk(
          id: 'p1',
          tokoId: 't1',
          nama: 'Ultra Milk UHT',
          harga: 17500,
          stok: 14,
          satuan: 'Pouch',
          kategori: 'Minuman',
          isTersedia: true,
        ),
        Produk(
          id: 'p2',
          tokoId: 't1',
          nama: 'Indomie Spesial',
          harga: 16200,
          stok: 25,
          satuan: 'Pack',
          kategori: 'Makanan',
          isTersedia: true,
        ),
        Produk(
          id: 'p3',
          tokoId: 't1',
          nama: 'Bimoli Spesial',
          harga: 33900,
          stok: 6,
          satuan: 'Pouch',
          kategori: 'Sembako',
          isTersedia: true,
        ),
      ],
      memuat: false,
      page: 1,
      totalPages: 1,
    );
  }

  @override
  Future<void> muatUlang() async {}

  @override
  Future<void> muatBerikutnya() async {}

  @override
  void cari(String value) {}

  @override
  void filterKategori(String value) {}
}

void main() {
  setUpAll(loadTestFonts);

  Future<void> openShell(WidgetTester tester) async {
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

  testWidgets('golden home beranda', (tester) async {
    await openShell(tester);
    expect(find.textContaining('Kilat Murah Hari Ini'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/home_page.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';
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
        Produk(
          id: 'p4',
          tokoId: 't1',
          nama: 'Minyak Goreng Filma',
          harga: 45000,
          stok: 20,
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

  Future<void> openHome(WidgetTester tester) async {
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
          pendingCheckoutProvider.overrideWithValue(
            const AsyncValue.data(false),
          ),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: HomePage(
              now: () => DateTime(2026, 10, 26, 18, 41, 30),
              onGoToTab: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Baris Kilat adalah satu-satunya ListView horizontal di beranda
  // (Scrollable horizontal lain milik field teks pencarian).
  Finder kilatRow() => find.byWidgetPredicate(
    (w) => w is ListView && w.scrollDirection == Axis.horizontal,
  );

  testWidgets('baris Kilat menampilkan kartu keempat yang mengintip',
      (tester) async {
    await openHome(tester);
    expect(kilatRow(), findsOneWidget);
    // Kartu keempat mulai di dalam viewport tapi ujung kanannya lewat
    // dari lebar layar: persis efek "mengintip" di referensi.
    final card = tester.getRect(find.byKey(const Key('product-p4')));
    expect(card.left, lessThan(390));
    expect(card.right, greaterThan(390));
  });

  testWidgets('baris Kilat bisa discroll ke samping', (tester) async {
    await openHome(tester);
    final before = tester.getRect(find.byKey(const Key('product-p4')));
    expect(before.right, greaterThan(390));
    await tester.drag(kilatRow(), const Offset(-200, 0));
    await tester.pump();
    // Setelah discroll, kartu keempat terlihat penuh dan bergeser ke kiri.
    final after = tester.getRect(find.byKey(const Key('product-p4')));
    expect(after.right, lessThanOrEqualTo(390));
    expect(after.left, lessThan(before.left));
  });

  testWidgets('tombol + Keranjang di kartu beranda menambah keranjang',
      (tester) async {
    await openHome(tester);
    // Baris Kilat awalnya di bawah lipatan (tinggi baris 288), jadi
    // halaman discroll dulu sampai tombolnya terlihat dan bisa diketuk.
    await tester.drag(
      find.text('Kilat Murah Hari Ini'),
      const Offset(0, -250),
    );
    await tester.pump();
    expect(find.widgetWithText(FilledButton, '+ Keranjang'), findsWidgets);
    await tester.tap(
      find.widgetWithText(FilledButton, '+ Keranjang').first,
    );
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    final cart = container.read(keranjangProvider('u1'));
    expect(cart.items, hasLength(1));
    expect(cart.items.first.produk.id, 'p1');
    expect(cart.items.first.qty, 1);
    // Badge tas di header ikut berubah jadi 1.
    expect(find.byKey(const Key('cart-badge-1')), findsOneWidget);
  });
}

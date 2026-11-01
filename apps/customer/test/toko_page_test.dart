import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/toko_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'catalog_flow_test.dart' show openCatalog, tapKey;
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

const _p1 = Produk(
  id: 'p1',
  tokoId: 't1',
  nama: 'Indomie Spesial',
  harga: 16200,
  stok: 5,
  satuan: 'pcs',
  kategori: 'Mie',
  isTersedia: true,
);
const _p2 = Produk(
  id: 'p2',
  tokoId: 't1',
  nama: 'Beras Pilihan',
  harga: 50000,
  stok: 10,
  satuan: 'kg',
  kategori: 'Beras',
  isTersedia: true,
);

const _tokoPenuh = Toko(
  id: 't1',
  nama: 'Toko Diponegoro',
  alamat: 'Jl. Diponegoro No. 42',
  telepon: '0618291122',
  deskripsi: 'Toko sembako dekat kampus',
  kategori: ['Sembako'],
  radiusKm: 5,
  status: 'buka',
  metodeKirim: ['Kurir'],
  jamBuka: '08:00:00',
  jamTutup: '23:00:00',
  produk: [_p1, _p2],
);

const _tokoKosong = Toko(
  id: 't1',
  nama: 'Toko Kosong',
  alamat: 'Jl. Kosong No. 1',
  telepon: '',
  kategori: [],
  radiusKm: 3,
  status: 'buka',
  metodeKirim: [],
  produk: [],
);

Future<AuthFixture> openToko(WidgetTester tester, Toko toko) async {
  final fixture = AuthFixture()..installStorage();
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(fixture.storage),
        keranjangStorageProvider.overrideWithValue(fixture.storage),
        apiClientProvider.overrideWithValue(fixture.api.client),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        detailTokoProvider.overrideWith((ref, id) async => toko),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        // Seperti shell asli yang selalu mengawasi keranjang (badge):
        // tanpa watcher, provider autoDispose gugur di tengah tambahItem.
        home: const _TokoTestHome(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return fixture;
}

/// Pembungkus tes: mengawasi keranjang lalu menampilkan TokoPage.
class _TokoTestHome extends ConsumerWidget {
  const _TokoTestHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(keranjangProvider('u1'));
    return const TokoPage('t1');
  }
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('store page shows real detail and catalog-variant cards', (
    tester,
  ) async {
    await openToko(tester, _tokoPenuh);
    expect(find.text('Toko Diponegoro'), findsOneWidget);
    expect(find.text('Buka'), findsOneWidget);
    expect(find.text('Buka 08:00 - 23:00'), findsOneWidget);
    expect(find.text('Jl. Diponegoro No. 42'), findsOneWidget);
    expect(find.text('0618291122'), findsOneWidget);
    expect(find.text('Toko sembako dekat kampus'), findsOneWidget);
    expect(find.text('Sembako'), findsOneWidget);
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(find.text('2 produk'), findsOneWidget);
    expect(find.byKey(const Key('product-p1')), findsOneWidget);
    expect(find.byKey(const Key('product-p2')), findsOneWidget);
    // Varian katalog: tidak ada badge diskon placeholder (itu hanya
    // varian beranda).
    expect(find.byKey(const Key('badge-diskon-p1')), findsNothing);
    expect(find.byKey(const Key('badge-diskon-p2')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('store page hides absent fields and shows empty state', (
    tester,
  ) async {
    await openToko(tester, _tokoKosong);
    expect(find.text('Toko Kosong'), findsOneWidget);
    expect(find.text('Belum ada produk di toko ini'), findsOneWidget);
    expect(find.text('0 produk'), findsOneWidget);
    expect(find.text('Tentang'), findsNothing);
    expect(find.text('Telepon'), findsNothing);
    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Pengiriman'), findsNothing);
    expect(find.text('Radius'), findsOneWidget);
    expect(find.text('3 km'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('add to cart from the store catalog actually adds', (
    tester,
  ) async {
    // Viewport tinggi seperti golden test: seluruh halaman toko muat
    // tanpa scroll, jadi tombol + Keranjang di bawah kartu bisa diketuk.
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await openToko(tester, _tokoPenuh);
    final button = find.descendant(
      of: find.byKey(const Key('product-p1')),
      matching: find.widgetWithText(FilledButton, '+ Keranjang'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    // Jangan pumpAndSettle di sini: ia memajukan timer sampai snackbar
    // 4 detik habis dan hilang sebelum sempat diperiksa. Pompa bertahap
    // sampai snackbar muncul (tambahItem sudah selesai saat snackbar
    // tampil, jadi simpanan keranjang pun sudah tertulis).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Ditambahkan ke keranjang').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Ditambahkan ke keranjang'), findsOneWidget);
    expect(
      (fixture.saved['customer_cart_u1'] ?? '').contains('p1'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home name tap and arrow picker open the store page', (
    tester,
  ) async {
    await openCatalog(tester);
    await tapKey(tester, 'store-name');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(find.text('Jalan Diponegoro'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Katalog Toko'), findsNothing);
    await tapKey(tester, 'store-picker');
    expect(find.text('Pilih Toko'), findsOneWidget);
    await tapKey(tester, 'store-pick-t1');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cart store name opens the store page', (tester) async {
    await openCatalog(tester);
    await tapKey(tester, 'product-p1');
    expect(find.text('Detail Produk'), findsOneWidget);
    await tapKey(tester, 'add-cart');
    await tapKey(tester, 'detail-back');
    await tapKey(tester, 'open-cart');
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    await tapKey(tester, 'cart-store-name');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

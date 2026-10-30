import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/placeholder_diskon.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/cart_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

const _bimoli = Produk(
  id: 'p3',
  tokoId: 't1',
  nama: 'Bimoli Minyak Goreng 2L',
  harga: 33900,
  stok: 6,
  satuan: 'Pouch',
  kategori: 'Minyak Goreng',
  isTersedia: true,
);
const _ultra = Produk(
  id: 'p1',
  tokoId: 't1',
  nama: 'Ultra Milk UHT',
  harga: 17500,
  stok: 14,
  satuan: 'Pouch',
  kategori: 'Minuman',
  isTersedia: true,
);
const _indomie = Produk(
  id: 'p2',
  tokoId: 't1',
  nama: 'Indomie Spesial',
  harga: 16200,
  stok: 25,
  satuan: 'Pack',
  kategori: 'Makanan',
  isTersedia: true,
);

void main() {
  group('placeholder diskon (unit)', () {
    test('persen dan hemat dihitung dari harga asli placeholder', () {
      expect(placeholderDiskonUntuk(_bimoli)?.persenDiskon(33900), 14);
      expect(placeholderDiskonUntuk(_bimoli)?.hematPerItem(33900), 5600);
      expect(placeholderDiskonUntuk(_ultra)?.persenDiskon(17500), 13);
      expect(placeholderDiskonUntuk(_indomie)?.persenDiskon(16200), 10);
    });

    test('produk tanpa placeholder tidak punya diskon', () {
      const lain = Produk(
        id: 'pX',
        tokoId: 't1',
        nama: 'Produk Lain',
        harga: 10000,
        stok: 5,
        satuan: 'Pcs',
        kategori: 'Lain',
        isTersedia: true,
      );
      expect(placeholderDiskonUntuk(lain), isNull);
    });

    test('total hemat hanya item terpilih, dikali qty', () {
      final items = [
        const KeranjangItem(produk: _bimoli, qty: 2, dipilih: true),
        const KeranjangItem(produk: _ultra, qty: 1, dipilih: true),
        const KeranjangItem(produk: _indomie, qty: 1, dipilih: false),
      ];
      // 5600 x 2 + 2500 = 13700; Indomie tidak dipilih, tidak dihitung.
      expect(totalHematPlaceholder(items), 13700);
    });
  });

  group('placeholder diskon (widget keranjang)', () {
    setUpAll(loadTestFonts);

    Future<void> pumpCart(WidgetTester tester) async {
      final fixture = AuthFixture()..installStorage();
      fixture.saved['customer_cart_u1'] = jsonEncode({
        'version': 1,
        'checkout_selesai': <String>[],
        'items': [
          {'produk': _bimoli.toJson(), 'qty': 2, 'dipilih': true},
          {'produk': _ultra.toJson(), 'qty': 1, 'dipilih': true},
          {'produk': _indomie.toJson(), 'qty': 1, 'dipilih': true},
        ],
      });
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
            detailTokoProvider.overrideWith(
              (ref, id) async => const Toko(
                id: 't1',
                nama: 'Toko Diponegoro',
                alamat: 'Jl. Diponegoro No. 42',
                telepon: '0618291122',
                kategori: ['Sembako'],
                radiusKm: 5,
                status: 'buka',
                metodeKirim: ['Kurir'],
                jamTutup: '23:00',
              ),
            ),
          ],
          child: MaterialApp(
            theme: customerTheme(),
            debugShowCheckedModeBanner: false,
            home: const CartPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('badge dan harga coret tampil di kartu', (tester) async {
      await pumpCart(tester);
      expect(find.text('-14%'), findsOneWidget);
      expect(find.text('Rp 39.500'), findsOneWidget);
      expect(find.text('-13%'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);
      expect(find.text('-10%'), findsOneWidget);
      expect(find.text('Rp 18.000'), findsOneWidget);
      // Harga coret benar-benar dicoret, bukan teks harga biasa.
      final coret = tester.widget<Text>(find.text('Rp 39.500'));
      expect(coret.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('banner hemat di bawah checkout, nilainya terhitung', (
      tester,
    ) async {
      await pumpCart(tester);
      // 5600 x 2 + 2500 + 1800 = 15500.
      expect(
        find.text('Total kamu hemat Rp 15.500 di pesanan ini!'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('cart-savings-banner')), findsOneWidget);
    });

    testWidgets('banner ikut berubah saat item tidak dipilih', (tester) async {
      await pumpCart(tester);
      await tester.tap(find.byKey(const Key('cart-check-p3')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Bimoli keluar dari hitungan: 2500 + 1800 = 4300.
      expect(
        find.text('Total kamu hemat Rp 4.300 di pesanan ini!'),
        findsOneWidget,
      );
    });

    testWidgets('teks kategori/ukuran dibiarkan apa adanya', (tester) async {
      await pumpCart(tester);
      expect(find.text('Minyak Goreng • Pouch'), findsOneWidget);
    });
  });
}

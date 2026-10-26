import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/cart_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden keranjang belanja', (tester) async {
    final fixture = AuthFixture()..installStorage();
    // Isi keranjang lewat storage yang dipulihkan KeranjangNotifier: 3 produk
    // berbeda, qty 2+1+1 (badge 3 produk, checkout 4 barang, seperti referensi).
    fixture.saved['customer_cart_u1'] = jsonEncode({
      'version': 1,
      'checkout_selesai': <String>[],
      'items': [
        {
          'produk': const Produk(
            id: 'p3',
            tokoId: 't1',
            nama: 'Bimoli Minyak Goreng 2L',
            harga: 33900,
            stok: 6,
            satuan: 'Pouch',
            kategori: 'Minyak Goreng',
            isTersedia: true,
          ).toJson(),
          'qty': 2,
          'dipilih': true,
        },
        {
          'produk': const Produk(
            id: 'p1',
            tokoId: 't1',
            nama: 'Ultra Milk UHT',
            harga: 17500,
            stok: 14,
            satuan: 'Pouch',
            kategori: 'Minuman',
            isTersedia: true,
          ).toJson(),
          'qty': 1,
          'dipilih': true,
        },
        {
          'produk': const Produk(
            id: 'p2',
            tokoId: 't1',
            nama: 'Indomie Spesial',
            harga: 16200,
            stok: 25,
            satuan: 'Pack',
            kategori: 'Makanan',
            isTersedia: true,
          ).toJson(),
          'qty': 1,
          'dipilih': true,
        },
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
    expect(find.text('Pilih Semua (3 Produk)'), findsOneWidget);
    expect(find.text('Bimoli Minyak Goreng 2L'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/cart.png'),
    );
  });
}

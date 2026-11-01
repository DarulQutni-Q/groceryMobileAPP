import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/toko_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden halaman toko', (tester) async {
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
          detailTokoProvider.overrideWith(
            (ref, id) async => const Toko(
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
              produk: [
                Produk(
                  id: 'p1',
                  tokoId: 't1',
                  nama: 'Indomie Spesial',
                  harga: 16200,
                  stok: 5,
                  satuan: 'pcs',
                  kategori: 'Mie',
                  isTersedia: true,
                ),
                Produk(
                  id: 'p2',
                  tokoId: 't1',
                  nama: 'Beras Pilihan',
                  harga: 50000,
                  stok: 10,
                  satuan: 'kg',
                  kategori: 'Beras',
                  isTersedia: true,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const TokoPage('t1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Katalog Toko'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/toko.png'),
    );
  });
}

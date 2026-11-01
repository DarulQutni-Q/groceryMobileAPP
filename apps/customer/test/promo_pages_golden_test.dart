import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/beli_satu_gratis_satu_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/fresh_mart_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/lacak_kurir_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/minyak_beras_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_jsm_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/tebus_murah_page.dart';

import 'auth_state_test.dart';
import 'golden_test.dart' show loadTestFonts;
import 'pesanan_fixture.dart';

/// Screenshot (golden) 6 halaman promo khusus loop-3, dengan data mock
/// yang sama seperti promo_pages_test: produk toko tetap + pesanan fixture.
/// Dipakai juga sebagai bukti visual untuk user, bukan cuma regresi.
final _products = [
  {
    'id': 'p1',
    'toko_id': 't1',
    'nama': 'Indomie Spesial',
    'harga': 16200,
    'stok': 5,
    'satuan': 'pcs',
    'kategori': 'Mie',
    'is_tersedia': true,
  },
  {
    'id': 'p2',
    'toko_id': 't1',
    'nama': 'Beras Pulen',
    'harga': 50000,
    'stok': 10,
    'satuan': 'kg',
    'kategori': 'Beras',
    'is_tersedia': true,
  },
  {
    'id': 'p3',
    'toko_id': 't1',
    'nama': 'Minyak Goreng 2L',
    'harga': 34000,
    'stok': 8,
    'satuan': 'pcs',
    'kategori': 'Minyak',
    'is_tersedia': true,
  },
  {
    'id': 'p4',
    'toko_id': 't1',
    'nama': 'Sayur Bayam',
    'harga': 8000,
    'stok': 20,
    'satuan': 'ikat',
    'kategori': 'Sayur',
    'is_tersedia': true,
  },
  {
    'id': 'p5',
    'toko_id': 't1',
    'nama': 'Buah Apel',
    'harga': 25000,
    'stok': 15,
    'satuan': 'kg',
    'kategori': 'Buah',
    'is_tersedia': true,
  },
  {
    'id': 'p6',
    'toko_id': 't1',
    'nama': 'Biskuit Cokelat',
    'harga': 12000,
    'stok': 30,
    'satuan': 'pcs',
    'kategori': 'Camilan',
    'is_tersedia': true,
  },
];

Map<String, Object> _page(List data) => {
  'data': data,
  'meta': {'page': 1, 'per_page': 20, 'total': data.length, 'total_pages': 1},
};

Future<void> _pumpGolden(
  WidgetTester tester,
  Widget page, {
  bool pakaiPesananFixture = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final fixture = AuthFixture()..installStorage();
  fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
    switch (request.path) {
      case '/auth/me':
        return response({
          'id': 'customer-id',
          'nama': 'Pembeli',
          'email': 'p@example.com',
          'role': 'customer',
        });
      case '/kategori':
        return response(['Beras', 'Minyak', 'Sayur', 'Buah', 'Camilan', 'Mie']);
      case '/produk':
        final category = request.queryParameters['kategori'] as String?;
        final q = (request.queryParameters['q'] as String? ?? '').toLowerCase();
        return response(
          _page(
            _products
                .where(
                  (p) =>
                      (p['nama']! as String).toLowerCase().contains(q) &&
                      (category == null ||
                          category.isEmpty ||
                          p['kategori'] == category),
                )
                .toList(),
          ),
        );
      default:
        return response({'detail': 'not found'}, 404);
    }
  });
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(780, 1688);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://localhost'),
        storageProvider.overrideWithValue(fixture.storage),
        apiClientProvider.overrideWithValue(fixture.api.client),
        if (pakaiPesananFixture)
          pesananProvider.overrideWith((ref) async => pesananFixture()),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden promo jsm', (tester) async {
    await _pumpGolden(tester, const PromoJsmPage());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/promo_jsm.png'),
    );
  });

  testWidgets('golden tebus murah', (tester) async {
    await _pumpGolden(tester, const TebusMurahPage());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tebus_murah.png'),
    );
  });

  testWidgets('golden minyak beras', (tester) async {
    await _pumpGolden(tester, const MinyakBerasPage());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/minyak_beras.png'),
    );
  });

  testWidgets('golden fresh mart', (tester) async {
    await _pumpGolden(tester, const FreshMartPage());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/fresh_mart.png'),
    );
  });

  testWidgets('golden beli 1 gratis 1', (tester) async {
    await _pumpGolden(tester, const BeliSatuGratisSatuPage());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beli_1_gratis_1.png'),
    );
  });

  testWidgets('golden lacak kurir', (tester) async {
    await _pumpGolden(
      tester,
      const LacakKurirPage(),
      pakaiPesananFixture: true,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/lacak_kurir.png'),
    );
  });
}

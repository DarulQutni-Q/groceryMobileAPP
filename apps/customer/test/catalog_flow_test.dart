import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';

import 'auth_state_test.dart';

final products = [
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
    'nama': 'Beras Pilihan',
    'harga': 50000,
    'stok': 10,
    'satuan': 'kg',
    'kategori': 'Beras',
    'is_tersedia': true,
  },
];
final store = {
  'id': 't1',
  'nama': 'Toko Diponegoro',
  'alamat': 'Jalan Diponegoro',
  'telepon': '',
  'kategori': ['Sembako'],
  'radius_km': 5,
  'status': 'buka',
  'metode_kirim': ['Instant'],
  'jam_buka': '08:00:00',
  'jam_tutup': '23:00:00',
};
Map<String, Object> page(List data) => {
  'data': data,
  'meta': {'page': 1, 'per_page': 20, 'total': data.length, 'total_pages': 1},
};

Future<AuthFixture> openCatalog(WidgetTester tester) async {
  final fixture = AuthFixture()..installStorage();
  fixture.saved['auth_session'] = jsonEncode({
    'access_token': 'access',
    'refresh_token': 'refresh',
  });
  fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
    fixture.calls.add(request);
    switch (request.path) {
      case '/auth/me':
        return response({
          'id': 'customer-id',
          'nama': 'Pembeli',
          'email': 'p@example.com',
          'role': 'customer',
        });
      case '/produk':
        final q = (request.queryParameters['q'] as String? ?? '').toLowerCase();
        final category = request.queryParameters['kategori'];
        return response(
          page(
            products
                .where(
                  (p) =>
                      (p['nama']! as String).toLowerCase().contains(q) &&
                      (category == null || p['kategori'] == category),
                )
                .toList(),
          ),
        );
      case '/produk/p1':
        return response(products.first);
      case '/produk/p2':
        return response(products.last);
      case '/kategori':
        return response(['Beras', 'Mie']);
      case '/toko':
        return response(page([store]));
      case '/toko/t1':
        return response({...store, 'produk': products});
      case '/promo':
        return response([
          {
            'id': 'demo',
            'judul': 'INDOMARET POINKU • PROMO SPESIAL',
            'deskripsi': 'Ada 4 voucher belanja diskon 50% siap kamu pakai.',
            'label_tombol': 'Klaim Semua Voucher',
            'is_demo': true,
          },
        ]);
      default:
        return response({'detail': 'Not Found'}, 404);
    }
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(fixture.storage),
        apiClientProvider.overrideWithValue(fixture.api.client),
      ],
      child: const CustomerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'home detail cart badge qty selections deletion and persisted restore',
    (tester) async {
      final fixture = await openCatalog(tester);
      expect(find.text('Klaim Semua Voucher'), findsOneWidget);
      expect(find.text('Poinku Member'), findsOneWidget);
      expect(find.text('Minyak & Beras'), findsOneWidget);
      await tapKey(tester, 'product-p1');
      expect(find.text('Deskripsi'), findsOneWidget);
      await tapKey(tester, 'detail-plus');
      await tapKey(tester, 'add-cart');
      await tapKey(tester, 'detail-back');
      expect(find.byKey(const Key('cart-badge-2')), findsOneWidget);
      await tapKey(tester, 'open-cart');
      expect(find.text('Dikirim dari Toko Diponegoro'), findsOneWidget);
      expect(find.byKey(const Key('cart-total-32400')), findsOneWidget);
      await tapKey(tester, 'cart-minus-p1');
      expect(find.byKey(const Key('cart-total-16200')), findsOneWidget);
      await tapKey(tester, 'select-all');
      expect(find.byKey(const Key('cart-total-0')), findsOneWidget);
      await tapKey(tester, 'select-all');
      await tapKey(tester, 'delete-selected');
      expect(find.text('Keranjang masih kosong'), findsOneWidget);
      expect(
        fixture.saved.keys.any((key) => key.startsWith('customer_cart_')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'search and category filter real products and small screen does not overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = await openCatalog(tester);
      await tester.enterText(
        find.byKey(const Key('catalog-search')),
        'indomie',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('product-p1')));
      expect(find.byKey(const Key('product-p2')), findsNothing);
      expect(
        fixture.calls
            .lastWhere((r) => r.path == '/produk')
            .queryParameters['q'],
        'indomie',
      );
      await tester.enterText(find.byKey(const Key('catalog-search')), '');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'category-Beras');
      expect(find.byKey(const Key('product-p1')), findsNothing);
      expect(find.byKey(const Key('product-p2')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

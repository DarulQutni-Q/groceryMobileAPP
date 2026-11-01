import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/beli_satu_gratis_satu_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/catalog_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/fresh_mart_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/lacak_kurir_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/minyak_beras_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pesanan_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_jsm_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/tebus_murah_page.dart';

import 'auth_state_test.dart';
import 'pesanan_fixture.dart';

/// Isi halaman promo khusus: spanduk + produk asli toko + keadaan kosong
/// + pelacak kurir. API dimock seperti catalog_flow_test: /kategori
/// mengembalikan nama kategori toko, /produk menyaring per kategori.
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

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  List<String>? kategori,
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://localhost'),
        storageProvider.overrideWithValue(fixture.storage),
        apiClientProvider.overrideWithValue(fixture.api.client),
        if (kategori != null)
          kategoriProvider.overrideWith((ref) async => kategori),
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
  testWidgets('Minyak & Beras: hanya Beras + Minyak', (tester) async {
    await _pumpPage(tester, const MinyakBerasPage());
    expect(find.text('Beras Pulen'), findsOneWidget);
    expect(find.text('Minyak Goreng 2L'), findsOneWidget);
    expect(find.text('Sayur Bayam'), findsNothing);
    expect(find.text('Indomie Spesial'), findsNothing);
    expect(find.text('Minyak & Beras'), findsNWidgets(2));
  });

  testWidgets('Fresh Mart: hanya Sayur + Buah', (tester) async {
    await _pumpPage(tester, const FreshMartPage());
    expect(find.text('Sayur Bayam'), findsOneWidget);
    expect(find.text('Buah Apel'), findsOneWidget);
    expect(find.text('Beras Pulen'), findsNothing);
    expect(find.text('Fresh Mart'), findsNWidgets(2));
  });

  testWidgets('Tebus Murah: hanya Camilan', (tester) async {
    await _pumpPage(tester, const TebusMurahPage());
    expect(find.text('Biskuit Cokelat'), findsOneWidget);
    expect(find.text('Beras Pulen'), findsNothing);
    expect(find.text('Tebus Murah Serba 5rb'), findsOneWidget);
    expect(
      find.text('Total akhir mengikuti hitungan toko saat checkout.'),
      findsOneWidget,
    );
  });

  testWidgets('Tebus Murah kosong: pesan jujur + tombol ke katalog', (
    tester,
  ) async {
    await _pumpPage(tester, const TebusMurahPage(), kategori: ['Mie']);
    expect(
      find.text('Belum ada produk tebus murah di toko ini.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lihat semua produk'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogPage), findsOneWidget);
  });

  testWidgets('Promo JSM: spanduk + semua produk + catatan harga', (
    tester,
  ) async {
    await _pumpPage(tester, const PromoJsmPage());
    expect(find.text('Promo JSM Akhir Pekan'), findsOneWidget);
    expect(find.text('Diskon s/d 40%'), findsOneWidget);
    expect(
      find.text('Total akhir mengikuti hitungan toko saat checkout.'),
      findsOneWidget,
    );
    expect(find.text('Beras Pulen'), findsOneWidget);
    expect(find.text('Indomie Spesial'), findsOneWidget);
  });

  testWidgets('Beli 1 Gratis 1: spanduk + produk + catatan harga', (
    tester,
  ) async {
    await _pumpPage(tester, const BeliSatuGratisSatuPage());
    expect(find.text('Beli 1 Gratis 1'), findsNWidgets(2));
    expect(find.text('Beli satu produk, gratis satu produk.'), findsOneWidget);
    expect(
      find.text('Total akhir mengikuti hitungan toko saat checkout.'),
      findsOneWidget,
    );
    expect(find.text('Beras Pulen'), findsOneWidget);
  });

  testWidgets('Lacak Kurir: aktif + riwayat + chat kurir', (tester) async {
    await _pumpPage(
      tester,
      const LacakKurirPage(),
      pakaiPesananFixture: true,
    );
    expect(find.text('Dalam Pengiriman'), findsOneWidget);
    expect(find.text('GM-1001'), findsOneWidget);
    expect(find.text('Diantar'), findsOneWidget);
    expect(find.text('Pesanan dalam perjalanan'), findsOneWidget);
    expect(find.text('Dikonfirmasi'), findsNWidgets(2));
    expect(find.text('Tiba'), findsNWidgets(2));
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('GM-0998'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    await tester.tap(find.text('Chat Kurir'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatDriverPage), findsOneWidget);
  });

  testWidgets('Lacak Kurir: riwayat dibatalkan perlu digulung', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const LacakKurirPage(),
      pakaiPesananFixture: true,
    );
    // Kartu ketiga di luar viewport awal (ListView malas): gulung dulu.
    await tester.scrollUntilVisible(find.text('GM-0995'), 200);
    expect(find.text('GM-0995'), findsOneWidget);
    expect(find.text('Dibatalkan'), findsOneWidget);
  });

  testWidgets('Lacak Kurir: tombol Buka Pesanan Saya', (tester) async {
    await _pumpPage(
      tester,
      const LacakKurirPage(),
      pakaiPesananFixture: true,
    );
    await tester.scrollUntilVisible(find.text('Buka Pesanan Saya'), 200);
    await tester.tap(find.text('Buka Pesanan Saya'));
    await tester.pumpAndSettle();
    expect(find.byType(PesananPage), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/checkout_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden konfirmasi pesanan', (tester) async {
    final fixture = AuthFixture()..installStorage();
    // Halaman checkout kini membaca preferensi metode dari
    // SharedPreferences; tanpa mock, load() menggantung di tes.
    SharedPreferences.setMockInitialValues({});
    // Checkout segar (tanpa sesi tersimpan): alamat + preview biaya
    // dimock lewat adapter HTTP, seperti checkout_flow_test.
    final original = fixture.api.client.dio.httpClientAdapter as CustomerAdapter;
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      if (request.path == '/alamat') {
        return response([
          {
            'id': 'a1',
            'label': 'Rumah',
            'nama_penerima': 'Darul Qutni',
            'no_hp': '+62 812-8899-2122',
            'alamat_lengkap': 'Jl. Diponegoro No. 42, Medan Polonia',
            'patokan': 'Titip di meja teras depan pagar hitam',
            'is_utama': true,
          },
        ]);
      }
      if (request.path == '/checkout/preview') {
        return response({
          'subtotal': 85100,
          'diskon': 25000,
          'ongkir': 0,
          'biaya_layanan': 1000,
          'total': 61100,
        });
      }
      return original.respond(request);
    });
    // 3 produk (Bimoli x1, Ultra Milk x2, Indomie x1 = 4 barang,
    // subtotal 85100), persis angka referensi (11).
    const bimoli = Produk(
      id: 'p3',
      tokoId: 't1',
      nama: 'Bimoli Minyak Goreng 2L',
      harga: 33900,
      stok: 6,
      satuan: 'Pouch',
      kategori: 'Minyak Goreng',
      isTersedia: true,
    );
    const ultra = Produk(
      id: 'p1',
      tokoId: 't1',
      nama: 'Ultra Milk UHT',
      harga: 17500,
      stok: 14,
      satuan: 'Pouch',
      kategori: 'Minuman',
      isTersedia: true,
    );
    const indomie = Produk(
      id: 'p2',
      tokoId: 't1',
      nama: 'Indomie Spesial',
      harga: 16200,
      stok: 25,
      satuan: 'Pack',
      kategori: 'Makanan',
      isTersedia: true,
    );
    final items = [
      const KeranjangItem(produk: bimoli, qty: 1, dipilih: true),
      const KeranjangItem(produk: ultra, qty: 2, dipilih: true),
      const KeranjangItem(produk: indomie, qty: 1, dipilih: true),
    ];
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 2240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          keranjangStorageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          authProvider.overrideWith((_) => FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          home: CheckoutPage(items: items),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Pilih GoPay seperti referensi (default halaman adalah QRIS).
    await tester.tap(find.byKey(const Key('choose-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bayar-gopay')));
    await tester.pumpAndSettle();
    // Isi catatan pesanan seperti strip referensi (ketuk strip catatan;
    // tombol Ubah sekarang kembali ke keranjang).
    await tester.tap(find.byKey(const Key('checkout-note-strip')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Pagar hitam no. 42, Titip di meja teras.',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
    expect(find.text('Alamat Pengiriman'), findsOneWidget);
    expect(
      find.text('Pengantaran Kilat Toko (15-20 Menit)'),
      findsOneWidget,
    );
    expect(find.text('Ringkasan Belanja (4 Barang)'), findsOneWidget);
    expect(find.text('Metode Pembayaran'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('Rincian Pembayaran'), findsOneWidget);
    expect(find.text('Total Tagihan Belanja'), findsOneWidget);
    expect(find.text('Rp 61.100'), findsNWidgets(2));
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(find.text('Hemat Rp 25.000'), findsOneWidget);
    await expectLater(
      find.byType(CheckoutPage),
      matchesGoldenFile('goldens/checkout.png'),
    );
  });
}

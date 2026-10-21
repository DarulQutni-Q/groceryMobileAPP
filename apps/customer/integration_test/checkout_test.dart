import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/bootstrap.dart';
import 'package:grocery_shared/shared.dart';
import 'package:integration_test/integration_test.dart';

import 'catalog_test.dart' show waitFor, tapKey;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('live B3 address checkout COD success and empty cart', (
    tester,
  ) async {
    const account = String.fromEnvironment('B3_ACCOUNT');
    const password = String.fromEnvironment('B3_PASSWORD');
    const productIds = [
      String.fromEnvironment('B3_PRODUCT_1'),
      String.fromEnvironment('B3_PRODUCT_2'),
    ];
    expect(account, isNotEmpty);
    final storage = SecureStorage();
    await storage.clearSession();
    final client = ApiClient(baseUrl: 'http://10.0.2.2:8000', storage: storage);
    final api = AuthApi(client);
    final tokens = await api.loginCustomer(account, password);
    await storage.saveSession(tokens.accessToken, tokens.refreshToken);
    await storage.setRememberSession(true);
    final user = await api.getMe();
    final products = [
      for (final id in productIds) await ProdukApi(client).detail(id),
    ];
    await storage.clearCheckout(user.id);
    await storage.saveKeranjang(
      user.id,
      jsonEncode({
        'version': 1,
        'items': [
          for (final product in products)
            KeranjangItem(produk: product, qty: 1).toJson(),
        ],
      }),
    );
    await bootstrap('dev');
    await binding.convertFlutterSurfaceToImage();
    await waitFor(tester, find.byKey(const Key('cart-badge-2')));

    Future<void> capture(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    Future<void> scrollTo(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    await tapKey(tester, 'open-cart');
    await tester.tap(find.text('Checkout (2 Barang)'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Konfirmasi Pesanan'));
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Tambah Alamat Baru'));
    await tester.tap(find.text('Tambah Alamat Baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kantor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('alamat-nama')),
      'Pembeli GardenMart',
    );
    await tester.enterText(find.byKey(const Key('alamat-hp')), '081234567890');
    await tester.enterText(
      find.byKey(const Key('alamat-lengkap')),
      'Jalan Kantor 20, Jakarta',
    );
    await scrollTo(find.byKey(const Key('alamat-patokan')));
    await tester.enterText(
      find.byKey(const Key('alamat-patokan')),
      'Resepsionis lantai dasar',
    );
    await capture('01-form-alamat');
    await tester.tap(find.text('Simpan Alamat'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Pembeli GardenMart'));
    await capture('02-daftar-alamat');
    final choose = find.widgetWithText(TextButton, 'Pilih Alamat').last;
    await scrollTo(choose);
    await tester.tap(choose);
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Konfirmasi Pesanan'));
    expect(find.text('Jalan Kantor 20, Jakarta'), findsOneWidget);
    await capture('03-konfirmasi');
    await scrollTo(find.byKey(const Key('choose-payment')));
    await tester.tap(find.byKey(const Key('choose-payment')));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Metode Pembayaran'));
    await capture('04-metode-bayar');
    await scrollTo(find.byKey(const Key('bayar-cod')));
    await tester.tap(find.byKey(const Key('bayar-cod')));
    await tester.pumpAndSettle();
    await scrollTo(find.text('Total Tagihan Belanja'));
    await capture('05-rincian-cod');
    await tapKey(tester, 'checkout-pay');
    await waitFor(tester, find.text('Pesanan Berhasil Dibuat'));
    await capture('06-sukses-cod');
    final cart = jsonDecode((await storage.readKeranjang(user.id))!) as Map;
    expect(cart['items'], isEmpty);
    expect(await storage.readCheckout(user.id), isNull);
    final orders =
        (await client.dio.get<Map<String, dynamic>>('/pesanan')).data!['data']
            as List;
    expect(orders.first['total'], 18000);
    expect(orders.first['status'], 'baru');
    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'open-cart');
    await waitFor(tester, find.text('Keranjang masih kosong'));
    await capture('07-keranjang-kosong');
  });
}

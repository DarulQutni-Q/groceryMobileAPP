import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/bootstrap.dart';
import 'package:grocery_shared/shared.dart';
import 'package:integration_test/integration_test.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 70; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  }
  await IntegrationTestWidgetsFlutterBinding.instance.takeScreenshot(
    '99-failure',
  );
  expect(finder, findsOneWidget);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final previousError = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint(details.toString());
    previousError?.call(details);
  };
  testWidgets(
    'live B2 browse search filter cart qty selections persistence and empty state',
    (tester) async {
      const account = String.fromEnvironment('B2_ACCOUNT');
      const password = String.fromEnvironment('B2_PASSWORD');
      expect(account, isNotEmpty);
      final storage = SecureStorage();
      await storage.clearSession();
      final api = AuthApi(
        ApiClient(baseUrl: 'http://10.0.2.2:8000', storage: storage),
      );
      final session = await api.loginCustomer(account, password);
      await storage.saveSession(session.accessToken, session.refreshToken);
      await storage.setRememberSession(true);
      final user = await api.getMe();
      await storage.saveKeranjang(
        user.id,
        jsonEncode({'version': 1, 'items': []}),
      );
      await bootstrap('dev');
      await binding.convertFlutterSurfaceToImage();
      await waitFor(tester, find.text('Klaim Semua Voucher'));
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot(name);
      }

      await capture('01-beranda');
      await tester.enterText(
        find.byKey(const Key('catalog-search')),
        'indomie',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 600));
      final client = ApiClient(
        baseUrl: 'http://10.0.2.2:8000',
        storage: storage,
      );
      final found = await ProdukApi(client).listHalaman(q: 'indomie');
      expect(found.data, isNotEmpty);
      final product = found.data.first;
      await waitFor(tester, find.byKey(Key('product-${product.id}')));
      await tapKey(tester, 'product-${product.id}');
      await waitFor(tester, find.text('Deskripsi'));
      await capture('02-detail-produk');
      await tapKey(tester, 'detail-plus');
      await tapKey(tester, 'add-cart');
      await tapKey(tester, 'detail-back');
      await waitFor(tester, find.byKey(const Key('cart-badge-2')));
      await tester.ensureVisible(find.byKey(const Key('catalog-search')));
      await tapKey(tester, 'clear-search');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 600));
      await waitFor(tester, find.byKey(const Key('category-Beras')));
      await tapKey(tester, 'category-Beras');
      final rice = await ProdukApi(client).listHalaman(kategori: 'Beras');
      await waitFor(tester, find.byKey(Key('product-${rice.data.first.id}')));
      expect(find.byKey(Key('product-${product.id}')), findsNothing);
      await tapKey(tester, 'open-cart');
      await waitFor(tester, find.byKey(Key('cart-total-${product.harga * 2}')));
      await capture('03-keranjang-isi');
      await tapKey(tester, 'cart-plus-${product.id}');
      await waitFor(tester, find.byKey(Key('cart-total-${product.harga * 3}')));
      await tapKey(tester, 'cart-minus-${product.id}');
      await waitFor(tester, find.byKey(Key('cart-total-${product.harga * 2}')));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await bootstrap('dev');
      await waitFor(tester, find.byKey(const Key('cart-badge-2')));
      await tapKey(tester, 'open-cart');
      await waitFor(tester, find.byKey(Key('cart-total-${product.harga * 2}')));
      await tapKey(tester, 'select-all');
      await waitFor(tester, find.byKey(const Key('cart-total-0')));
      await tapKey(tester, 'select-all');
      await tapKey(tester, 'delete-selected');
      await waitFor(tester, find.text('Keranjang masih kosong'));
      await capture('04-keranjang-kosong');
      expect(tester.takeException(), isNull);
      client.dio.close();
      api.client.dio.close();
    },
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/payment_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';
import 'catalog_flow_test.dart' show openCatalog, tapKey;

Map<String, dynamic> checkoutResult(
  String method, {
  String status = 'pending',
}) => {
  'pesanan': {
    'id': 'o1',
    'kode': 'DG-12345',
    'status': 'baru',
    'alamat_kirim': 'Jalan Melati',
    'metode_kirim': 'Instant',
    'slot_waktu': 'Segera',
    'subtotal': 16200,
    'diskon': 0,
    'ongkir': 0,
    'biaya_layanan': 1000,
    'total': 17200,
    'items': [],
    'created_at': '2026-10-21T10:00:00Z',
  },
  'pembayaran': {
    'id': 'b1',
    'pesanan_id': 'o1',
    'metode': method,
    'status': status,
    'jumlah': 17200,
    'payment_url': method == 'cod'
        ? null
        : 'https://checkout-staging.xendit.co/web/test',
    'perlu_rekonsiliasi': false,
  },
};

Future<AuthFixture> openCheckout(WidgetTester tester) async {
  final fixture = await openCatalog(tester);
  final original = fixture.api.client.dio.httpClientAdapter as CustomerAdapter;
  fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
    if (request.path == '/alamat') {
      return response([
        {
          'id': 'a1',
          'label': 'Rumah',
          'nama_penerima': 'Pembeli',
          'no_hp': '081234567890',
          'alamat_lengkap': 'Jalan Melati',
          'is_utama': true,
        },
      ]);
    }
    if (request.path == '/checkout/preview') {
      return response({
        'subtotal': 16200,
        'diskon': 0,
        'ongkir': 0,
        'biaya_layanan': 1000,
        'total': 17200,
      });
    }
    if (request.path == '/checkout') {
      fixture.calls.add(request);
      expect(
        request.headers['Idempotency-Key'],
        matches(r'^\d{13}-[a-f0-9]{32}$'),
      );
      expect((request.data as Map)['total_dikonfirmasi'], 17200);
      return response(
        checkoutResult((request.data as Map)['metode_bayar'] as String),
        201,
      );
    }
    return original.respond(request);
  });
  await tapKey(tester, 'product-p1');
  await tapKey(tester, 'add-cart');
  await tapKey(tester, 'detail-back');
  await tapKey(tester, 'open-cart');
  await tester.tap(find.text('Checkout (1 Barang)'));
  await tester.pumpAndSettle();
  return fixture;
}

void main() {
  testWidgets(
    'cart checkout selects COD and clears purchased items after order succeeds',
    (tester) async {
      final fixture = await openCheckout(tester);
      expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
      expect(find.text('Jalan Melati'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('choose-payment')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-payment')));
      await tester.pumpAndSettle();
      expect(find.text('RECOMMENDED'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('bayar-cod')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bayar-cod')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkout-pay')));
      await tester.pumpAndSettle();
      expect(find.text('Pesanan Berhasil Dibuat'), findsOneWidget);
      expect(find.text('DG-12345'), findsOneWidget);
      expect(fixture.calls.where((r) => r.path == '/checkout').length, 1);
      final cart =
          jsonDecode(fixture.saved['customer_cart_customer-id']!) as Map;
      expect(cart['items'], isEmpty);
      expect(fixture.saved['customer_checkout_customer-id'], isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'paid payment retries only local finalization when cart storage fails',
    (tester) async {
      final fixture = AuthFixture()..installStorage();
      fixture.api.client.dio.httpClientAdapter = CustomerAdapter(
        (request) async =>
            response(checkoutResult('qris', status: 'paid')['pembayaran']!),
      );
      var finalized = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutApiProvider.overrideWithValue(
              CheckoutApi(fixture.api.client),
            ),
            paymentLauncherProvider.overrideWithValue((_) async => true),
          ],
          child: MaterialApp(
            home: PaymentPage(
              result: HasilCheckout.fromJson(checkoutResult('qris')),
              onPaid: () async {
                finalized++;
                if (finalized == 1) throw StateError('storage failed');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(finalized, 1);
      expect(find.text('Coba Lagi'), findsNothing);
      expect(find.text('Perbarui Keranjang'), findsOneWidget);
      await tester.tap(find.text('Perbarui Keranjang'));
      await tester.pumpAndSettle();
      expect(finalized, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

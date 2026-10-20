import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seller/app.dart';
import 'package:seller/features/auth/application/auth_provider.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> waitClosed(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A3 seller accepts undoes rejects and completes live orders', (
    tester,
  ) async {
    await const FlutterSecureStorage().deleteAll();
    await dotenv.load(fileName: '.env.dev.example');
    final storage = SecureStorage();
    final client = ApiClient(
      baseUrl: dotenv.env['API_BASE_URL']!,
      storage: storage,
    );
    final tokens = await AuthApi(client).registerSeller(
      namaPemilik: 'Pemilik A3',
      namaToko: 'Uji Pesanan A3',
      email: 'a3-device-${DateTime.now().microsecondsSinceEpoch}@example.com',
      password: 'SandiUji123!',
    );
    await storage.saveSession(tokens.accessToken, tokens.refreshToken);
    await storage.markOnboardingSeen();
    final produk = await ProdukApi(client).create({
      'nama': 'Beras Uji A3',
      'harga': 15000,
      'stok': 20,
      'satuan': 'kg',
      'kategori': 'Beras',
    });
    final orders = <Pesanan>[];
    for (var i = 0; i < 3; i++) {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/pesanan/internal/test',
        data: {
          'items': [
            {'produk_id': produk.id, 'qty': i + 1},
          ],
          'alamat_kirim': 'Jalan Pengujian A3 nomor ${i + 1}',
          'slot_waktu': 'Hari ini 15.00-17.00',
          'ongkir': 5000,
          'catatan': 'Pesanan pengujian dev',
        },
      );
      orders.add(Pesanan.fromJson(response.data!));
    }
    final api = PesananApi(client);
    expect((await api.list(status: 'baru')).length, 3);
    void start() => runApp(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          apiBaseUrlProvider.overrideWithValue(dotenv.env['API_BASE_URL']!),
        ],
        child: const SellerApp(),
      ),
    );
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await binding.takeScreenshot(name);
    }

    Future<void> openOrder(Pesanan order) async {
      final text = find.text(order.kode);
      await tester.scrollUntilVisible(text, 200);
      await tester.tap(text);
      await waitFor(tester, find.text('Barang Pesanan'));
    }

    start();
    await tester.pump();
    await binding.convertFlutterSurfaceToImage();
    await waitFor(tester, find.text('Toko Uji Pesanan A3'));
    await tester.tap(find.byKey(const Key('nav-pesanan')));
    await waitFor(tester, find.text(orders.last.kode));
    await capture('01-pesanan-baru');
    await openOrder(orders.last);
    await capture('04-detail-baru');
    for (final label in ['Diterima', 'Dikemas', 'Diantar', 'Tiba']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Tolak Pesanan'));
    await waitFor(tester, find.text('Kenapa pesanan ditolak?'));
    await tester.tap(find.text('Stok Habis'));
    await capture('05-modal-tolak');
    await tester.tap(find.byKey(const Key('pesanan-reject-confirm')));
    await waitClosed(tester, find.text('Kenapa pesanan ditolak?'));
    await waitFor(tester, find.text('Pesanan Ditolak'));
    expect((await api.detail(orders.last.id)).tolakAlasan, 'Stok Habis');
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pesanan-tab-selesai')));
    await waitFor(tester, find.text(orders.last.kode));
    await capture('03-pesanan-selesai');
    await tester.tap(find.byKey(const Key('pesanan-tab-baru')));
    await tester.pumpAndSettle();
    await openOrder(orders[1]);
    await tester.tap(find.text('Terima Pesanan'));
    await waitFor(tester, find.text('Pesanan ${orders[1].kode} diterima'));
    await capture('06-konfirmasi-terima');
    await tester.tap(find.text('Urungkan'));
    await waitClosed(tester, find.text('Pesanan ${orders[1].kode} diterima'));
    await waitFor(tester, find.text('Terima Pesanan'));
    expect((await api.detail(orders[1].id)).status, 'baru');
    await tester.tap(find.text('Terima Pesanan'));
    await waitFor(tester, find.text('Pesanan ${orders[1].kode} diterima'));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pesanan-tab-diproses')));
    await waitFor(tester, find.text(orders[1].kode));
    await capture('02-pesanan-diproses');
    await tester.tap(find.text('Tandai siap diantar'));
    await waitFor(tester, find.text('Dikemas'));
    expect((await api.detail(orders[1].id)).status, 'dikemas');
    await openOrder(orders[1]);
    await capture('07-detail-dikemas');
    await tester.tap(find.text('Mulai antar'));
    await waitFor(tester, find.text('Tandai tiba'));
    expect((await api.detail(orders[1].id)).status, 'diantar');
    await capture('08-detail-diantar');
    await tester.tap(find.text('Tandai tiba'));
    await waitFor(tester, find.text('Pesanan Selesai'));
    expect((await api.detail(orders[1].id)).status, 'selesai');
    await capture('09-detail-selesai');
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pesanan-tab-baru')));
    await tester.pumpAndSettle();
    await openOrder(orders.first);
    await tester.tap(find.text('Tolak Pesanan'));
    await waitFor(tester, find.text('Lainnya'));
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pesanan-reject-reason')),
      'Produk pengujian tidak tersedia',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('10-modal-lainnya');
    await tester.tap(find.byKey(const Key('pesanan-reject-confirm')));
    await waitClosed(tester, find.text('Kenapa pesanan ditolak?'));
    await waitFor(tester, find.text('Pesanan Ditolak'));
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Belum ada pesanan baru'));
    await capture('11-pesanan-kosong');
    await tester.tap(find.byKey(const Key('pesanan-tab-selesai')));
    await tester.pumpAndSettle();
    expect((await api.list(status: 'selesai')).length, 3);
    await capture('03-pesanan-selesai');
    start();
    await tester.pump(const Duration(seconds: 3));
    await waitFor(tester, find.text('Toko Uji Pesanan A3'));
    await tester.tap(find.byKey(const Key('nav-pesanan')));
    await waitFor(tester, find.text('Belum ada pesanan baru'));
    await tester.tap(find.byKey(const Key('pesanan-tab-selesai')));
    await waitFor(tester, find.text(orders.first.kode));
    await capture('12-pesanan-sesi-pulih');
    expect(tester.takeException(), isNull);
    client.dio.close();
  });
}

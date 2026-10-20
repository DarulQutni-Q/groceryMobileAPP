import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seller/app.dart';
import 'package:seller/features/auth/application/auth_provider.dart';

import 'a2_test.dart' as store;
import 'a3_test.dart' as orders;

void main() {
  store.main();
  orders.main();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'A4 live report empty, sales, ranges, tooltip and network recovery',
    (tester) async {
      await const FlutterSecureStorage().deleteAll();
      await dotenv.load(fileName: '.env.dev.example');
      final storage = SecureStorage();
      final client = ApiClient(
        baseUrl: dotenv.env['API_BASE_URL']!,
        storage: storage,
      );
      final token = await AuthApi(client).registerSeller(
        namaPemilik: 'Pemilik A4',
        namaToko: 'Uji Laporan A4',
        email: 'a4-device-${DateTime.now().microsecondsSinceEpoch}@example.com',
        password: 'SandiUji123!',
      );
      await storage.saveSession(token.accessToken, token.refreshToken);
      await storage.markOnboardingSeen();
      runApp(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue(dotenv.env['API_BASE_URL']!),
          ],
          child: const SellerApp(),
        ),
      );
      await tester.pump();
      await binding.convertFlutterSurfaceToImage();
      await store.waitFor(tester, find.text('Toko Uji Laporan A4'));
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        await binding.takeScreenshot(name);
      }

      await tester.tap(find.byKey(const Key('nav-laporan')));
      await store.waitFor(tester, find.text('Belum ada data penjualan.'));
      await capture('20-laporan-kosong');
      await tester.ensureVisible(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat Pesanan'));
      await store.waitFor(tester, find.byKey(const Key('pesanan-tab-baru')));
      for (final tab in ['baru', 'diproses', 'selesai']) {
        await tester.tap(find.byKey(Key('pesanan-tab-$tab')));
        await store.waitFor(tester, find.text('Belum ada pesanan $tab'));
        await capture('21-pesanan-$tab-kosong');
      }
      final products = <Produk>[];
      for (var i = 1; i <= 6; i++) {
        products.add(
          await ProdukApi(client).create({
            'nama': 'Produk A4 $i',
            'harga': i * 10000,
            'stok': 30,
            'satuan': 'pcs',
            'kategori': 'Sembako',
          }),
        );
      }
      for (var i = 0; i < 3; i++) {
        final response = await client.dio.post<Map<String, dynamic>>(
          '/pesanan/internal/test',
          data: {
            'items': i == 0
                ? [
                    for (final p in products) {'produk_id': p.id, 'qty': 1},
                  ]
                : [
                    {'produk_id': products.first.id, 'qty': i + 1},
                  ],
            'ongkir': 5000,
            'alamat_kirim': 'Jalan Laporan A4',
          },
        );
        final order = Pesanan.fromJson(response.data!);
        final api = PesananApi(client);
        await api.terima(order.id);
        for (final status in ['dikemas', 'diantar', 'selesai']) {
          await api.updateStatus(order.id, status);
        }
      }
      final report = LaporanApi(client);
      expect((await report.getRingkasan()).totalPenjualan, 275000);
      expect((await report.getRingkasan()).jumlahPesanan, 3);
      expect((await report.getProdukTerlaris()).first.totalQty, 6);
      await tester.tap(find.byKey(const Key('nav-laporan')));
      await store.waitFor(tester, find.text('Total Penjualan 7 hari'));
      expect(find.text('Rp 275.000'), findsOneWidget);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(7),
      );
      await capture('22-laporan-7-hari');
      final chart = find.byType(BarChart);
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      final rect = tester.getRect(chart);
      await tester.tapAt(Offset(rect.right - rect.width / 14, rect.top + 75));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BarChart>(chart)
            .data
            .barGroups
            .last
            .showingTooltipIndicators,
        isNotEmpty,
      );
      await capture('23-laporan-tooltip');
      await tester.scrollUntilVisible(
        find.text('Lihat semua'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture('24-produk-terlaris');
      await tester.tap(find.text('Lihat semua'));
      await store.waitFor(tester, find.text('Segera hadir'));
      await tester.tap(find.byKey(const Key('laporan-range-30h')));
      await store.waitFor(tester, find.text('Total Penjualan 30 hari'));
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(30),
      );
      await capture('25-laporan-30-hari');
      await tester.tap(find.byKey(const Key('nav-beranda')));
      await tester.pumpAndSettle();
      final signal = File('${Directory.systemTemp.path}/a4-network-stage');
      await signal.writeAsString('disable', flush: true);
      await store.waitFor(tester, find.text('Tidak ada koneksi internet'));
      await capture('26-beranda-offline');
      await signal.writeAsString('enable', flush: true);
      await tester.runAsync(() async {
        for (var i = 0; i < 30; i++) {
          if (await signal.readAsString() == 'online') return;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        fail('Pengendali emulator belum memulihkan jaringan.');
      });
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba lagi'));
      await store.waitFor(tester, find.text('Perlu Tindakan'));
      await store.waitFor(tester, find.text('Rp 275.000'));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('Tidak ada koneksi internet'), findsNothing);
      await capture('27-beranda-online-kembali');
      await signal.writeAsString('done', flush: true);
      expect(tester.takeException(), isNull);
      client.dio.close();
    },
  );
}

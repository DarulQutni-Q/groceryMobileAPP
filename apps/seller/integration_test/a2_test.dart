import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seller/app.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/store/application/store_provider.dart';
import 'package:seller/features/store/presentation/product_editor.dart';
import 'package:seller/features/store/presentation/toko_editor.dart';
import 'package:seller/features/store/presentation/hours_editor.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> waitForClosed(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'A2 stores profile, hours, product photo and availability across sessions',
    (tester) async {
      await const FlutterSecureStorage().deleteAll();
      await dotenv.load(fileName: '.env.dev.example');
      final bytes = (await rootBundle.load('assets/references/login.png'))
          .buffer
          .asUint8List();
      void start() => runApp(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            apiBaseUrlProvider.overrideWithValue(dotenv.env['API_BASE_URL']!),
            photoPickerProvider.overrideWithValue(
              (_) async => XFile.fromData(
                bytes,
                path: 'produk-uji.png',
                name: 'produk-uji.png',
                mimeType: 'image/png',
              ),
            ),
          ],
          child: const SellerApp(),
        ),
      );
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        await binding.takeScreenshot(name);
      }

      start();
      await tester.pump();
      await binding.convertFlutterSurfaceToImage();
      await capture('auth-01-splash');
      await tester.pump(const Duration(seconds: 3));
      await waitFor(tester, find.text('Lanjut'));
      await capture('auth-02-onboarding');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await capture('auth-03-login');
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      await capture('auth-04-daftar-akun');
      final email =
          'a2-device-${DateTime.now().microsecondsSinceEpoch}@example.com';
      await tester.enterText(
        find.byKey(const Key('Nama Pemilik')),
        'Pemilik A2',
      );
      await tester.enterText(find.byKey(const Key('Nama Toko')), 'Uji A2');
      await tester.enterText(find.byKey(const Key('email')), email);
      await tester.enterText(
        find.byKey(const Key('Kata Sandi')),
        'SandiUji123!',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await waitFor(tester, find.text('Kategori Toko'));
      await capture('auth-05-daftar-info');
      await tester.tap(find.text('Sembako'));
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await capture('auth-06-daftar-pengiriman');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await waitFor(tester, find.text('Toko Kamu Sudah Terdaftar'));
      await capture('auth-07-daftar-sukses');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SellerApp)),
      );
      final tokoApi = container.read(tokoApiProvider);
      final api = container.read(produkApiProvider);
      expect((await tokoApi.getProfil()).kategori, ['Sembako']);
      expect((await tokoApi.getProfil()).metodeKirim, ['Instant']);
      await tester.ensureVisible(find.text('+ Tambah Produk'));
      await tester.tap(find.text('+ Tambah Produk'));
      await waitFor(tester, find.text('Perlu Tindakan'));
      await capture('01-beranda-tutup');
      await tester.tap(find.byKey(const Key('toko-status')));
      await waitFor(tester, find.text('3 Pesan baru menunggu'));
      await capture('02-beranda-buka');
      await tester.tap(find.byKey(const Key('nav-produk')));
      await tester.pumpAndSettle();
      await capture('03-produk-kosong');
      await tester.tap(find.text('+ Tambah Produk').first);
      await tester.pumpAndSettle();
      await capture('04-tambah-produk');
      await tester.ensureVisible(find.text('Simpan produk'));
      await tester.tap(find.text('Simpan produk'));
      await tester.pumpAndSettle();
      expect(find.textContaining('wajib'), findsWidgets);
      await capture('04-tambah-produk-validasi');
      await tester.ensureVisible(find.text('Foto Produk'));
      await tester.tap(find.text('Foto Produk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih dari galeri'));
      await waitFor(
        tester,
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      );
      await tester.enterText(
        find.byKey(const Key('produk-nama produk')),
        'Beras Uji A2',
      );
      await tester.enterText(
        find.byKey(const Key('produk-harga produk')),
        '15000',
      );
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Tambah stok'));
      }
      await tester.ensureVisible(find.byKey(const Key('produk-kategori')));
      await tester.enterText(find.byKey(const Key('produk-kategori')), 'Beras');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('05-tambah-produk-foto');
      await tester.tap(find.text('Simpan produk'));
      await waitForClosed(tester, find.byType(ProductEditor));
      await waitFor(tester, find.text('Tersedia'));
      await waitFor(tester, find.text('Beras Uji A2'));
      final products = await api.list();
      expect(products.length, 1);
      expect(products.single.stok, 4);
      expect(products.single.fotoUrl, isNotNull);
      await precacheImage(
        NetworkImage(
          Uri.parse(dotenv.env['API_BASE_URL']!)
              .resolve(products.single.fotoUrl!)
              .toString(),
        ),
        tester.element(find.byType(SellerApp)),
      );
      await capture('06-produk');
      await tester.tap(find.byKey(Key('toggle-${products.single.id}')));
      await waitFor(tester, find.text('Habis'));
      expect((await api.list()).single.isTersedia, isFalse);
      await capture('07-produk-habis');
      await tester.enterText(
        find.byKey(const Key('product-search')),
        'Produk tidak ada',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await waitFor(tester, find.textContaining('belum ada di tokomu'));
      FocusManager.instance.primaryFocus?.unfocus();
      await capture('08-produk-cari-kosong');
      await tester.tap(find.byKey(const Key('nav-toko')));
      await tester.pumpAndSettle();
      await capture('09-toko');
      await tester.tap(find.text('Info Toko'));
      await tester.pumpAndSettle();
      for (final entry in {
        'Nama Toko': 'Uji A2 Baru',
        'Alamat Toko': 'Jalan Uji 20',
        'Nomor Toko': '081234567890',
        'Deskripsi Singkat (Opsional)': 'Toko pengujian A2',
      }.entries) {
        final field = find.byKey(Key('toko-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await capture('10-info-toko');
      await tester.tap(find.text('Simpan'));
      await waitForClosed(tester, find.byType(TokoEditor));
      await waitFor(tester, find.text('Info Toko'));
      await waitFor(tester, find.text('Uji A2 Baru'));
      expect((await tokoApi.getProfil()).alamat, 'Jalan Uji 20');
      await tester.tap(find.text('Jam buka'));
      await waitFor(tester, find.text('Senin'));
      await tester.tap(find.byType(Switch).first);
      await capture('11-jam-buka');
      await tester.tap(find.text('Simpan Jam Buka'));
      await waitForClosed(tester, find.byType(HoursEditor));
      await waitFor(tester, find.text('Info Toko'));
      expect((await tokoApi.getJamBuka()).first.isTutup, isFalse);
      await tester.tap(find.text('Pengiriman'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kurir Marketplace'));
      await capture('12-pengiriman');
      await tester.tap(find.text('Simpan'));
      await waitForClosed(tester, find.byType(TokoEditor));
      await waitFor(tester, find.text('Info Toko'));
      expect(
        (await tokoApi.getProfil()).metodeKirim,
        contains('Kurir Marketplace'),
      );
      await tester.tap(find.text('Rekening Pencairan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'BRI 1234567890');
      FocusManager.instance.primaryFocus?.unfocus();
      await capture('13-rekening');
      await tester.tap(find.text('Simpan'));
      await waitForClosed(tester, find.byType(TokoEditor));
      await waitFor(tester, find.text('Info Toko'));
      expect((await tokoApi.getProfil()).rekeningBank, 'BRI 1234567890');
      await tester.scrollUntilVisible(find.text('Keluar'), 200);
      await tester.tap(find.text('Keluar'));
      await waitFor(tester, find.text('Keluar dari toko?'));
      await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
      await waitFor(tester, find.text('Login ke Toko'));
      await tester.enterText(find.byKey(const Key('email')), email);
      await tester.enterText(
        find.byKey(const Key('Kata Sandi')),
        'SandiUji123!',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await waitFor(tester, find.text('Toko Uji A2 Baru'));
      start();
      await tester.pump(const Duration(seconds: 3));
      await waitFor(tester, find.text('Toko Uji A2 Baru'));
      expect(find.text('Login ke Toko'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture('14-sesi-pulih');
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/auth/presentation/reset_pages.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pengaturan_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/ubah_profil_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/metode_pembayaran_page.dart';

import 'auth_state_test.dart' show AuthFixture;

void main() {
  late AuthFixture fixture;

  Future<void> open(WidgetTester tester) async {
    // Pola yang sama dengan button_interactions_test: fixture + mock
    // dibuat di body tes, bukan di setUp.
    fixture = AuthFixture()..installStorage();
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/event'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') return '/tmp';
        return null;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          googleTokenProvider.overrideWithValue(() async => 'google-token'),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester) async {
    await tap(tester, find.text('Get Started'));
    await tester.enterText(
      find.byKey(const Key('login-identity')),
      'pembeli@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'SandiCustomer123!',
    );
    await tap(tester, find.text('Masuk Sekarang'));
    expect(find.text('Selamat pagi, Pembeli'), findsOneWidget);
  }

  Future<void> bukaPengaturan(WidgetTester tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Akun'));
    await tap(tester, find.text('Pengaturan'));
    expect(find.byType(PengaturanPage), findsOneWidget);
  }

  Finder headerBack() => find.descendant(
    of: find.byType(PengaturanPage),
    matching: find.byIcon(Icons.arrow_back),
  );

  Finder headerGear() => find.descendant(
    of: find.byType(PengaturanPage),
    matching: find.byIcon(Icons.settings_outlined),
  );

  testWidgets('pengaturan: kembali ke tab Akun', (tester) async {
    await bukaPengaturan(tester);
    await tap(tester, headerBack());
    expect(find.byType(PengaturanPage), findsNothing);
    expect(find.text('Pengaturan'), findsOneWidget);
  });

  testWidgets('pengaturan: gerigi membuka dialog Tentang', (tester) async {
    await bukaPengaturan(tester);
    await tap(tester, headerGear());
    expect(find.text('Tentang GardenMart'), findsOneWidget);
    expect(find.textContaining('Info versi belum tersedia'), findsOneWidget);
    await tap(tester, find.text('Tutup'));
    expect(find.text('Tentang GardenMart'), findsNothing);
  });

  testWidgets('pengaturan: ubah profil membuka halaman edit', (tester) async {
    await bukaPengaturan(tester);
    await tap(tester, find.text('Ubah Profil & Identitas'));
    expect(find.byType(UbahProfilPage), findsOneWidget);
  });

  testWidgets('pengaturan: KTP jujur, bukan klaim terverifikasi', (
    tester,
  ) async {
    await bukaPengaturan(tester);
    expect(find.text('Belum tersedia'), findsOneWidget);
    expect(find.text('Terverifikasi'), findsNothing);
    await tap(tester, find.text('Verifikasi Identitas & KTP'));
    expect(find.text('Verifikasi Identitas & KTP'), findsWidgets);
    await tap(tester, find.text('Tutup'));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('pengaturan: ganti kata sandi membuka reset email', (
    tester,
  ) async {
    await bukaPengaturan(tester);
    expect(find.text('Lewat email terdaftar'), findsOneWidget);
    expect(find.text('Diubah 3 hari yang lalu'), findsNothing);
    await tap(tester, find.text('Ganti kata sandi'));
    expect(find.byType(ResetPage), findsOneWidget);
  });

  testWidgets('pengaturan: PIN toggle tersimpan dan pulih', (tester) async {
    await bukaPengaturan(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tap(tester, find.text('PIN Transaksi & Biometrik'));
    expect(find.byIcon(Icons.check), findsNothing);
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('metode_biometrik'), isFalse);
    // Keluar lalu masuk lagi: state harus pulih dari prefs, bukan default.
    await tap(tester, headerBack());
    await tap(tester, find.text('Pengaturan'));
    expect(find.byType(PengaturanPage), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    await tap(tester, find.text('PIN Transaksi & Biometrik'));
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('metode_biometrik'), isTrue);
  });

  testWidgets('pengaturan: metode pembayaran membuka halaman', (tester) async {
    await bukaPengaturan(tester);
    await tap(tester, find.text('Metode Pembayaran'));
    expect(find.byType(MetodePembayaranPage), findsOneWidget);
    await tap(tester, find.byIcon(Icons.arrow_back));
    expect(find.byType(PengaturanPage), findsOneWidget);
  });

  testWidgets('pengaturan: bahasa hanya Indonesia dan tersimpan', (
    tester,
  ) async {
    await bukaPengaturan(tester);
    await tap(tester, find.text('Bahasa Aplikasi'));
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bahasa Indonesia (ID)'),
      ),
      findsOneWidget,
    );
    expect(find.text('Bahasa lain belum tersedia.'), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bahasa Indonesia (ID)'),
      ),
    );
    expect(find.byType(AlertDialog), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bahasa_aplikasi'), 'id');
  });

  testWidgets('pengaturan: baris cache membuka dialog konfirmasi', (
    tester,
  ) async {
    await bukaPengaturan(tester);
    // Ukuran cache terukur dari imageCache: di alur aplikasi penuh nilainya
    // bukan 0 (artwork login sudah ter-decode), tapi tidak pernah hardcode.
    expect(find.text('Cache: 48,2 MB'), findsNothing);
    final subtitleBefore = tester
        .widget<Text>(find.textContaining('Cache:'))
        .data;
    expect(subtitleBefore, startsWith('Cache: '));
    await tap(tester, find.text('Penyimpanan & Cache'));
    expect(find.text('Hapus cache gambar dalam memori?'), findsOneWidget);
    await tap(tester, find.text('Batal'));
    expect(find.byType(AlertDialog), findsNothing);
    // Batal tidak mengubah apa pun: subtitle tetap nilai terukur semula.
    expect(find.text(subtitleBefore!), findsOneWidget);
  });
}

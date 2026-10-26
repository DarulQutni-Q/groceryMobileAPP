import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/catalog_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/metode_pembayaran_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pengaturan_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/scan_qr_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/struk_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/ubah_profil_page.dart';

import 'auth_state_test.dart' show AuthFixture;

void main() {
  late AuthFixture fixture;

  Future<void> open(WidgetTester tester, {List<String>? kategori}) async {
    // PENTING: fixture + mock harus dibuat di body tes, bukan di setUp.
    // Membuat AuthFixture di setUp membuat pumpAndSettle menggantung
    // (pola customer_flow_test juga membuat fixture di body tiap tes).
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
    // Clipboard di flutter_tester headless tidak pernah dijawab (menggantung);
    // mock via SystemChannels.platform (JSONMethodCodec, BUKAN MethodChannel
    // standar yang merusak decode SystemChrome).
    String? clipboardText;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>?;
          clipboardText = args?['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': clipboardText};
        }
        return null;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          googleTokenProvider.overrideWithValue(() async => 'google-token'),
          if (kategori != null)
            kategoriProvider.overrideWith((ref) async => kategori),
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

  // Tombol di ujung bawah list (mis. Lihat struk di history card) belum
  // ter-build sebelum list di-scroll (di luar cacheExtent); gulung sampai
  // tombol muncul, lalu tap yang pertama (ada dua history card).
  // JANGAN oper finder .first ke scrollUntilVisible: ia melempar saat kosong.
  Future<void> tapBottom(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
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

  group('decideScanAction', () {
    test('null dan kosong diabaikan', () {
      expect(decideScanAction(null), isNull);
      expect(decideScanAction('   '), isNull);
    });
    test('URL dibuka di browser', () {
      final result = decideScanAction('https://example.com/promo');
      expect(result?.action, ScanAction.openUrl);
      expect(result?.value, 'https://example.com/promo');
    });
    test('teks lain jadi kata kunci produk', () {
      final result = decideScanAction('  Beras  ');
      expect(result?.action, ScanAction.searchProduct);
      expect(result?.value, 'Beras');
    });
  });

  testWidgets('login email memanggil /auth/login bukan /auth/login/phone',
      (tester) async {
    await open(tester);
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
    expect(
      fixture.calls.where((call) => call.path == '/auth/login'),
      isNotEmpty,
    );
    expect(
      fixture.calls.where((call) => call.path == '/auth/login/phone'),
      isEmpty,
    );
  });

  testWidgets('login HP memanggil /auth/login/phone', (tester) async {
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tester.enterText(
      find.byKey(const Key('login-identity')),
      '081234567890',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'SandiCustomer123!',
    );
    await tap(tester, find.text('Masuk Sekarang'));
    expect(find.text('Selamat pagi, Pembeli'), findsOneWidget);
    expect(
      fixture.calls.where((call) => call.path == '/auth/login/phone'),
      isNotEmpty,
    );
    expect(
      fixture.calls.where((call) => call.path == '/auth/login'),
      isEmpty,
    );
  });

  testWidgets('daftar pakai HP mengirim phone di payload', (tester) async {
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Daftar Akun Baru'));
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'pembeli@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-phone')),
      '081234567890',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'SandiCustomer123!',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'SandiCustomer123!',
    );
    await tap(tester, find.text('Daftar'));
    expect(find.text('Selamat pagi, Pembeli'), findsOneWidget);
    final payload =
        fixture.calls.firstWhere((call) => call.path == '/auth/register').data
            as Map;
    expect(payload['phone'], '081234567890');
    expect(payload['email'], 'pembeli@example.com');
    expect(payload['role'], 'customer');
  });

  testWidgets('bel membuka notifikasi dan kembali ke home', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.byTooltip('Notifikasi'));
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.arrow_back));
    expect(find.text('Selamat pagi, Pembeli'), findsOneWidget);
  });

  testWidgets('ikon scan membuka halaman scan', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.byTooltip('Scan produk'));
    expect(find.byType(ScanQrPage), findsOneWidget);
  });

  testWidgets('kategori Promo JSM membuka tab Promo', (tester) async {
    await open(tester, kategori: ['Beras', 'Minyak', 'Sayur', 'Buah']);
    await login(tester);
    await tap(tester, find.text('Promo JSM'));
    expect(find.byType(PromoPage), findsOneWidget);
    expect(find.text('Promo & Kupon'), findsOneWidget);
  });

  testWidgets('kategori Minyak dan Beras membuka katalog', (tester) async {
    await open(tester, kategori: ['Beras', 'Minyak', 'Sayur', 'Buah']);
    await login(tester);
    await tap(tester, find.text('Minyak & Beras'));
    expect(find.byType(CatalogPage), findsOneWidget);
  });

  testWidgets('kategori Tagihan PLN membuka dialog jujur', (tester) async {
    await open(tester, kategori: ['Beras', 'Minyak', 'Sayur', 'Buah']);
    await login(tester);
    await tap(tester, find.text('Tagihan PLN'));
    expect(find.text('Tagihan PLN'), findsWidgets);
    expect(find.text('Tutup'), findsOneWidget);
    await tap(tester, find.text('Tutup'));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('kategori Lacak Kurir membuka tab Pesanan', (tester) async {
    await open(tester, kategori: ['Beras', 'Minyak', 'Sayur', 'Buah']);
    await login(tester);
    await tap(tester, find.text('Lacak Kurir'));
    expect(find.text('Pesanan Saya'), findsOneWidget);
  });

  testWidgets('promo: filter, klaim, dan voucher saya', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Promo'));
    await tap(tester, find.text('Cashback'));
    expect(find.text('Cashback 15.000 Poin Sembako'), findsOneWidget);
    expect(find.text('Diskon 30% Produk Segar (Fresh Mart)'), findsNothing);
    expect(find.text('Promo Mingguan'), findsNothing);
    await tap(tester, find.text('Klaim'));
    expect(find.text('Sudah Klaim'), findsOneWidget);
    await tap(tester, find.text('Semua Promo'));
    expect(find.text('Promo Mingguan'), findsOneWidget);
    await tap(tester, find.text('Voucher saya'));
    expect(find.text('Voucher Saya (2)'), findsOneWidget);
    expect(find.text('Promo Mingguan'), findsNothing);
    await tap(tester, find.text('Tampilkan Semua'));
    expect(find.text('Promo Mingguan'), findsOneWidget);
  });

  testWidgets('pesanan: chat kirim, telepon dialog, struk, search',
      (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Pesanan'));
    await tap(tester, find.text('Chat Driver'));
    expect(find.byType(ChatDriverPage), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Halo pak, saya di depan pagar',
    );
    await tap(tester, find.byIcon(Icons.send));
    expect(find.text('Halo pak, saya di depan pagar'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.arrow_back));
    await tap(tester, find.byIcon(Icons.phone));
    expect(find.text('Pak Budi'), findsWidgets);
    await tap(tester, find.text('Tutup'));
    await tapBottom(tester, find.text('Lihat struk'));
    expect(find.byType(StrukPage), findsOneWidget);
    await tap(tester, find.byIcon(Icons.arrow_back));
    await tap(tester, find.byIcon(Icons.search));
    expect(find.byType(CatalogPage), findsOneWidget);
  });

  testWidgets('struk: share menyalin dan download menyimpan', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Pesanan'));
    await tapBottom(tester, find.text('Lihat struk'));
    await tap(tester, find.byIcon(Icons.ios_share));
    await tester.pump();
    final clip = await Clipboard.getData('text/plain');
    expect(clip?.text, contains('GARDENMART SUPERMARKET'));
    // Tunggu snackbar share benar-benar hilang agar tidak menutupi tombol
    // Download di footer (tap sebelumnya meleset karena tertutup snackbar).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(SnackBar).evaluate().isEmpty) break;
    }
    await tester.scrollUntilVisible(find.text('Download struk'), 200);
    await tester.pumpAndSettle();
    // Bukti download jalan adalah file PDF-nya (nama dari nomor struk mock).
    // Snackbar tidak bisa dipakai di tes: ScaffoldMessenger + runAsync tidak
    // merendernya di tester, tapi file membuktikan handler selesai penuh.
    final pdfFile = File('/tmp/struk__GM_8921_20261003.pdf');
    if (pdfFile.existsSync()) pdfFile.deleteSync();
    await tester.tap(find.widgetWithText(FilledButton, 'Download struk'));
    // File IO nyata butuh event loop nyata; tanpa runAsync ia deadlock di
    // zona fake-async tes.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    expect(pdfFile.existsSync(), isTrue);
    expect(pdfFile.lengthSync(), greaterThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('pengaturan: ubah profil tersimpan dan tampil di akun',
      (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Akun'));
    await tap(tester, find.text('Pengaturan'));
    expect(find.byType(PengaturanPage), findsOneWidget);
    await tap(tester, find.text('Ubah Profil & Identitas'));
    expect(find.byType(UbahProfilPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Darul Baru');
    await tap(tester, find.text('Simpan'));
    expect(find.byType(PengaturanPage), findsOneWidget);
    await tap(tester, find.byIcon(Icons.arrow_back));
    expect(find.text('Darul Baru'), findsOneWidget);
  });

  testWidgets('pengaturan: PIN, cache, bahasa, KTP', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Akun'));
    await tap(tester, find.text('Pengaturan'));
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tap(tester, find.text('PIN Transaksi & Biometrik'));
    expect(find.byIcon(Icons.check), findsNothing);
    await tap(tester, find.text('PIN Transaksi & Biometrik'));
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tap(tester, find.text('Bersihkan'));
    expect(find.text('Hapus cache gambar dalam memori?'), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bersihkan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cache: 0 MB'), findsOneWidget);
    await tap(tester, find.text('Bahasa Aplikasi'));
    // Subtitle baris Bahasa di halaman juga 'Bahasa Indonesia (ID)', jadi
    // batasi ke dialog agar tidak ganda.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bahasa Indonesia (ID)'),
      ),
      findsOneWidget,
    );
    expect(find.text('Bahasa lain belum tersedia.'), findsOneWidget);
    await tap(tester, find.text('Tutup'));
    await tap(tester, find.text('Verifikasi Identitas & KTP'));
    expect(find.text('Verifikasi Identitas & KTP'), findsWidgets);
    await tap(tester, find.text('Tutup'));
  });

  testWidgets('metode: pilih Mandiri dan simpan tersimpan di prefs',
      (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('Akun'));
    await tap(tester, find.text('Pengaturan'));
    await tap(tester, find.text('Metode Pembayaran'));
    expect(find.byType(MetodePembayaranPage), findsOneWidget);
    await tap(tester, find.byKey(const Key('metode-mandiri')));
    await tap(tester, find.text('Simpan'));
    expect(find.byType(PengaturanPage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('metode_utama'), 1);
  });

  testWidgets('keranjang: kebab mengosongkan', (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.byIcon(Icons.shopping_bag_outlined));
    await tap(tester, find.byIcon(Icons.more_vert));
    expect(find.text('Kosongkan Keranjang'), findsOneWidget);
    await tester.ensureVisible(find.text('Kosongkan Keranjang'));
    await tester.tap(find.text('Kosongkan Keranjang'));
    await tester.pump();
    expect(find.text('Keranjang dikosongkan'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

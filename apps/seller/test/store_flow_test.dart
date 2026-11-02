import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/app.dart';
import 'package:seller/core/seller_theme.dart';
import 'package:seller/core/network.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/store/presentation/seller_shell.dart';
import 'package:seller/features/store/presentation/store_widgets.dart';
import 'package:seller/features/store/presentation/toko_editor.dart';
import 'package:seller/shared/auth_layout.dart';
import 'support/store_fixture.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  Future<void> open(
    WidgetTester tester, {
    StoreFixture? fixture,
    bool fullApp = false,
    List<dynamic> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = fixture ?? StoreFixture();
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      dio: dio,
      storage: SecureStorage(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionStateProvider.overrideWith((ref) => Stream.value(true)),
          apiBaseUrlProvider.overrideWithValue(dio.options.baseUrl),
          apiClientProvider.overrideWithValue(api),
          ...overrides,
        ],
        child: fullApp
            ? const SellerApp()
            : MaterialApp(
                theme: sellerTheme(),
                home: const SellerShell(
                  user: User(
                    id: 'u1',
                    nama: 'Pemilik Uji',
                    email: 'uji@example.com',
                    role: 'seller',
                    namaToko: 'Toko Uji',
                  ),
                ),
              ),
      ),
    );
    if (fullApp) await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('failed logout keeps the store available and can be retried', (
    tester,
  ) async {
    var failDelete = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (call.method == 'delete' && failDelete) {
              throw PlatformException(code: 'storage_unavailable');
            }
            if (call.method == 'read') {
              return (call.arguments as Map)['key'] == 'auth_session'
                  ? '{"access_token":"access","refresh_token":"refresh"}'
                  : 'true';
            }
            return null;
          },
        );
    await open(tester, fullApp: true);
    await tester.tap(find.byKey(const Key('nav-toko')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Keluar'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sesi belum dapat dihapus. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.drag(find.byType(SnackBar), const Offset(0, 300));
    await tester.pumpAndSettle();
    failDelete = false;
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Login ke Toko'), findsOneWidget);
  });

  testWidgets('logout waits for confirmation and cancel keeps the session', (
    tester,
  ) async {
    var deletions = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (call.method == 'delete') deletions++;
            return null;
          },
        );
    await open(tester);
    await tester.tap(find.byKey(const Key('nav-toko')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Keluar'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(deletions, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Batal'));
    await tester.pumpAndSettle();
    expect(deletions, 0);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(deletions, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product search stays usable with keyboard on a 320x568 phone', (
    tester,
  ) async {
    await open(tester);
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byKey(const Key('nav-produk')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.enterText(find.byKey(const Key('product-search')), 'beras');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed delete reports the backend error inside the editor', (
    tester,
  ) async {
    await open(tester, fixture: StoreFixture()..failDelete = true);
    await tester.tap(find.byKey(const Key('nav-produk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beras Uji'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hapus produk'));
    await tester.tap(find.text('Hapus produk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Produk belum bisa dihapus'), findsWidgets);
  });

  testWidgets('successful delete closes editor even when refresh fails', (
    tester,
  ) async {
    final fixture = StoreFixture()..failRefreshAfterDelete = true;
    await open(tester, fixture: fixture);
    await tester.tap(find.byKey(const Key('nav-produk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beras Uji'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hapus produk'));
    await tester.tap(find.text('Hapus produk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Produk'), findsNothing);
    expect(find.text('Daftar produk belum dapat dimuat'), findsOneWidget);
    fixture.failProductList = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Beras Uji'), findsNothing);
    expect(find.text('Daftar produk belum dapat dimuat'), findsNothing);
  });

  testWidgets(
    'store status, products, search, availability and reports are reachable',
    (tester) async {
      await open(tester);
      expect(find.text('Perlu Tindakan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toko-status')));
      await tester.pumpAndSettle();
      expect(find.text('Buka'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-produk')));
      await tester.pumpAndSettle();
      expect(find.text('Beras Uji'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Habis'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('product-search')),
        'tidak ada',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.textContaining('belum ada di tokomu'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-laporan')));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada data penjualan.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lihat Pesanan'), 150);
    await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('Lihat Pesanan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'product form validates photo and store hours stay reachable on a small phone',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('nav-produk')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Tambah Produk'));
      await tester.pumpAndSettle();
      expect(find.text('Foto Produk Wajib'), findsOneWidget);
      await tester.ensureVisible(find.text('Simpan produk'));
      await tester.tap(find.text('Simpan produk'));
      await tester.pumpAndSettle();
      expect(find.text('Nama produk wajib diisi'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-toko')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jam buka'));
      await tester.pumpAndSettle();
      expect(find.text('Senin'), findsOneWidget);
      await tester.ensureVisible(find.text('Minggu'));
      expect(find.text('Minggu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toko screen status action chip toggles store status', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('nav-toko')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('toko-status-action')), findsOneWidget);
    expect(find.text('Toko sedang tutup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toko-status-action')));
    await tester.pumpAndSettle();

    expect(find.text('Toko sedang buka'), findsOneWidget);
  });

  testWidgets(
    'upload logo toko successfully updates store logo and refreshes profile',
    (tester) async {
      final fixture = StoreFixture();
      await open(
        tester,
        fixture: fixture,
        overrides: [
          logoPickerProvider.overrideWithValue(
            () async => XFile.fromData(
              Uint8List.fromList([1, 2, 3, 4]),
              name: 'logo_baru.png',
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('nav-toko')));
      await tester.pumpAndSettle();

      expect(find.byType(ReferenceArtwork), findsWidgets);

      await tester.tap(find.text('Info Toko'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Foto'), findsOneWidget);
      await tester.tap(find.text('Ubah Foto'));
      await tester.pumpAndSettle();

      expect(find.text('Logo toko berhasil diperbarui'), findsOneWidget);
      expect(fixture.profile['logo_url'], '/uploads/logo-toko.png');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    },
  );

  testWidgets('upload logo toko handles failure and displays error snackbar', (
    tester,
  ) async {
    final fixture = StoreFixture()..failLogoUpload = true;
    await open(
      tester,
      fixture: fixture,
      overrides: [
        logoPickerProvider.overrideWithValue(
          () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3, 4]),
            name: 'bad_logo.png',
          ),
        ),
      ],
    );
    await tester.tap(find.byKey(const Key('nav-toko')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info Toko'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ubah Foto'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal mengunggah logo'), findsOneWidget);
    expect(find.text('Ubah Foto'), findsOneWidget);
  });

  testWidgets(
    'TokoLogo shows ReferenceArtwork when logoUrl is empty or null, and Image.network when present',
    (tester) async {
      const tokoNoLogo = Toko(
        id: 't1',
        nama: 'Toko Test',
        alamat: 'Alamat Test',
        telepon: '08123456789',
        kategori: ['Sembako'],
        metodeKirim: ['Instant'],
        radiusKm: 5,
        status: 'tutup',
        logoUrl: null,
      );
      const tokoWithLogo = Toko(
        id: 't1',
        nama: 'Toko Test',
        alamat: 'Alamat Test',
        telepon: '08123456789',
        kategori: ['Sembako'],
        metodeKirim: ['Instant'],
        radiusKm: 5,
        status: 'tutup',
        logoUrl: '/uploads/custom-logo.png',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TokoLogo(toko: tokoNoLogo),
                  TokoLogo(toko: tokoWithLogo),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ReferenceArtwork), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
        findsOneWidget,
      );
    },
  );
}

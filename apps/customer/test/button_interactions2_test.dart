import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';

import 'auth_state_test.dart' show AuthFixture, CustomerAdapter, response;

void main() {
  late AuthFixture fixture;

  Future<void> open(
    WidgetTester tester, {
    ApiClient? apiClient,
    AuthFixture? preset,
    List<Alamat>? alamat,
  }) async {
    // Pola sama seperti button_interactions_test: fixture + mock dibuat di
    // body tes, bukan di setUp (setUp membuat pumpAndSettle menggantung).
    // preset dipakai tes reset agar apiClient kustom memakai storage sama.
    fixture = preset ?? (AuthFixture()..installStorage());
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
          apiClientProvider.overrideWithValue(
            apiClient ?? fixture.api.client,
          ),
          googleTokenProvider.overrideWithValue(() async => 'google-token'),
          if (alamat != null)
            alamatProvider.overrideWithValue(AsyncValue.data(alamat)),
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

  Future<void> tutupDialog(WidgetTester tester) async {
    await tap(tester, find.text('Tutup'));
    expect(find.byType(AlertDialog), findsNothing);
  }

  testWidgets('tombol Apple ID membuka dialog jujur, bukan snackbar',
      (tester) async {
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Apple ID'));
    expect(find.text('Masuk dengan Apple'), findsOneWidget);
    expect(
      find.textContaining('backend belum mendukung login Apple'),
      findsOneWidget,
    );
    await tutupDialog(tester);
  });

  testWidgets('tombol History di Poinku membuka dialog riwayat',
      (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('14.850 Poin'));
    await tap(tester, find.text('History'));
    expect(find.text('Riwayat Poin'), findsOneWidget);
    expect(
      find.textContaining('backend belum menyediakan data loyalitas'),
      findsOneWidget,
    );
    await tutupDialog(tester);
  });

  testWidgets('tombol Tukar di Poinku membuka dialog penukaran',
      (tester) async {
    await open(tester);
    await login(tester);
    await tap(tester, find.text('14.850 Poin'));
    // Tukar ada di ListView rewards (lazy) dan ada banyak: scrollUntilVisible
    // gagal karena butuh tepat satu elemen. Pakai tombol pertama yang
    // benar-benar bisa ditekan (hitTestable) + ensureVisible.
    final tukar = find.widgetWithText(FilledButton, 'Tukar').hitTestable();
    await tester.ensureVisible(tukar.first);
    await tester.pumpAndSettle();
    await tester.tap(tukar.first);
    await tester.pumpAndSettle();
    expect(find.text('Penukaran Poin'), findsOneWidget);
    expect(
      find.textContaining('backend belum menyediakan penukaran poin'),
      findsOneWidget,
    );
    await tutupDialog(tester);
  });

  testWidgets('link GPS di Alamat membuka dialog titik peta',
      (tester) async {
    // PinpointCard hanya tampil bila alamatProvider ada datanya.
    await open(tester, alamat: [
      const Alamat(
        id: 'a1',
        label: 'Rumah',
        namaPenerima: 'Pembeli',
        noHp: '081234567890',
        alamatLengkap: 'Jl. Diponegoro No. 42',
        isUtama: true,
      ),
    ]);
    await login(tester);
    await tap(tester, find.text('Akun'));
    await tap(tester, find.text('Alamat Pengiriman'));
    await tapBottom(tester, find.textContaining('Atur Titik Peta GPS'));
    expect(find.text('Titik Peta GPS'), findsOneWidget);
    expect(
      find.textContaining('tetap bisa diisi manual'),
      findsOneWidget,
    );
    await tutupDialog(tester);
  });

  testWidgets('reset password email tak dikenal menampilkan pesan benar',
      (tester) async {
    // Adapter khusus: forgot-password mengembalikan 404, sisanya normal.
    fixture = AuthFixture()..installStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CustomerAdapter((request) async {
      if (request.path == '/auth/me') {
        return response({
          'id': 'customer-id',
          'nama': 'Pembeli',
          'email': 'pembeli@example.com',
          'role': 'customer',
          'phone': '+6281234567890',
          'nama_toko': null,
        });
      }
      if (request.path == '/auth/forgot-password') {
        return response({'detail': 'Email tidak ditemukan'}, 404);
      }
      return response(
        {'access_token': 'access', 'refresh_token': 'refresh'},
      );
    });
    final apiClient = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: fixture.storage,
      dio: dio,
    );
    await open(tester, preset: fixture, apiClient: apiClient);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Lupa Kata Sandi?'));
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'tidakada@example.com',
    );
    // Snackbar hanya hidup 4 detik: tap manual + pump secukupnya (bukan
    // pumpAndSettle yang memajukan waktu melewati durasi snackbar).
    // _send bersifat async (await Dio): butuh 2-3 frame sampai snackbar
    // tampil, tapi total waktu jauh di bawah 4 detik.
    await tester.ensureVisible(find.text('Send Email'));
    await tester.tap(find.text('Send Email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Email tidak ditemukan'), findsOneWidget);
  });
}

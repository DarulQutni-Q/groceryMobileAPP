import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/auth/presentation/reset_pages.dart';

import 'auth_state_test.dart' show AuthFixture, CustomerAdapter, response;

void main() {
  late AuthFixture fixture;

  Future<void> open(WidgetTester tester) async {
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
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'splash registration validates passwords then opens customer placeholder',
    (tester) async {
      fixture = AuthFixture()..installStorage();
      await open(tester);
      expect(find.text('Belanja Segar & Lengkap\nTanpa Ribet'), findsOneWidget);
      await tap(tester, find.text('Get Started'));
      expect(find.text('Ingat Saya'), findsOneWidget);
      await tap(tester, find.text('Daftar Akun Baru'));
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'pembeli@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'SandiCustomer123!',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm')),
        'TidakSama123!',
      );
      await tap(tester, find.text('Daftar'));
      expect(find.text('Kata sandi harus sama'), findsOneWidget);
      expect(
        fixture.calls.where((call) => call.path == '/auth/register'),
        isEmpty,
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
      // Form register sesuai referensi tidak lagi meminta nomor telepon;
      // phone opsional di backend, jadi payload tidak membawanya.
      expect(payload['phone'], isNull);
      expect(payload['email'], 'pembeli@example.com');
      expect(payload['role'], 'customer');
    },
  );

  testWidgets('wrong phone credentials show Indonesian red snackbar', (
    tester,
  ) async {
    fixture = AuthFixture()..installStorage();
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter(
      (request) async =>
          response({'detail': 'Nomor handphone atau kata sandi salah'}, 401),
    );
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tester.enterText(
      find.byKey(const Key('login-identity')),
      '081234567890',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Salah123!',
    );
    await tap(tester, find.text('Masuk Sekarang'));
    expect(find.text('Nomor handphone atau kata sandi salah'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      Colors.red.shade700,
    );
  });

  testWidgets(
    'missing reset endpoint shows soon without pretending email was sent',
    (tester) async {
      fixture = AuthFixture()..installStorage();
      fixture.api.client.dio.httpClientAdapter = CustomerAdapter(
        (request) async => response({'detail': 'Not Found'}, 404),
      );
      await open(tester);
      await tap(tester, find.text('Get Started'));
      await tap(tester, find.text('Lupa Kata Sandi?'));
      expect(find.text('Forget Password'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('reset-email')),
        'pembeli@example.com',
      );
      await tap(tester, find.text('Send Email'));
      expect(find.text('Segera hadir'), findsOneWidget);
      expect(find.text('Email Reset Sent!'), findsNothing);
    },
  );

  testWidgets('successful reset response reaches email sent screen', (
    tester,
  ) async {
    fixture = AuthFixture()..installStorage();
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Lupa Kata Sandi?'));
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'pembeli@example.com',
    );
    await tap(tester, find.text('Send Email'));
    expect(find.text('Email Reset Sent!'), findsOneWidget);
    expect(find.text('Open My Email'), findsOneWidget);
  });

  testWidgets(
    'forms stay scrollable on small screen with keyboard and large text',
    (tester) async {
      fixture = AuthFixture()..installStorage();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tap(tester, find.text('Get Started'));
      await tap(tester, find.text('Daftar Akun Baru'));
      await tester.enterText(
        find.byKey(const Key('register-confirm')),
        'SandiCustomer123!',
      );
      await tap(tester, find.text('Daftar'));
      expect(tester.takeException(), isNull);
      expect(find.text('Email wajib diisi'), findsOneWidget);
    },
  );
  testWidgets('invalid phone stays on login without an API call', (
    tester,
  ) async {
    fixture = AuthFixture()..installStorage();
    await open(tester);
    await tap(tester, find.text('Get Started'));
    await tester.enterText(
      find.byKey(const Key('login-identity')),
      '123',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'SandiCustomer123!',
    );
    await tap(tester, find.text('Masuk Sekarang'));
    expect(find.text('Nomor handphone Indonesia tidak valid'), findsOneWidget);
    expect(
      fixture.calls.where((call) => call.path == '/auth/login/phone'),
      isEmpty,
    );
  });

  testWidgets('email sent opens email app through the external launcher', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openEmailProvider.overrideWithValue((uri) async {
            opened = uri;
            return true;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ResetPage(sent: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Open My Email'));
    expect(opened?.scheme, 'mailto');
    expect(opened?.path, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller/app.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/auth/presentation/account_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  testWidgets('small phone and keyboard keep login and validation reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async =>
              (call.arguments as Map)['key'] == 'seller_onboarding_seen'
              ? 'true'
              : null,
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
        ],
        child: const SellerApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Login ke Toko'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.ensureVisible(find.byKey(const Key('email')));
    await tester.enterText(find.byKey(const Key('email')), 'bukan-email');
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Alamat email tidak valid'), findsOneWidget);
    expect(find.text('Kata Sandi wajib diisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'splash leads to onboarding and login; Google missing config is safe',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
          ],
          child: const SellerApp(),
        ),
      );
      expect(find.text('Belanja Mudah,\nKebutuhan Lengkap'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Terima Pesanan dari\nSatu Layar'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Login ke Toko'), findsOneWidget);
      expect(find.byKey(const Key('email')), findsOneWidget);
      await tester.ensureVisible(find.text('Login Dengan Google'));
      await tester.tap(find.text('Login Dengan Google'));
      await tester.pumpAndSettle();
      expect(find.text('Login Google belum dikonfigurasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AccountForm shows optional labels in login mode and required labels in register mode',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AccountForm(register: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Login mode
      expect(find.text('Nama Pemilik (Opsional)'), findsOneWidget);
      expect(find.text('Nama Toko (Opsional)'), findsOneWidget);
      expect(find.text('Boleh dikosongkan untuk login'), findsNWidgets(2));

      // Register mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AccountForm(register: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nama Pemilik'), findsOneWidget);
      expect(find.text('Nama Toko'), findsOneWidget);
      expect(find.text('Masukkan Nama Pemilik'), findsOneWidget);
      expect(find.text('Masukkan Nama Toko'), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seller/bootstrap.dart';

Future<void> _capture(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 250));
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'seller registers, completes setup, logs in, and restores session',
    (tester) async {
      await const FlutterSecureStorage().deleteAll();
      await bootstrap('dev');
      await tester.pump();
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await _capture(tester, binding, '01-splash');
      for (final asset in ['onboarding.png', 'login.png', 'store-info.png']) {
        await precacheImage(
          AssetImage('assets/references/$asset'),
          tester.element(find.byType(MaterialApp)),
        );
      }
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Terima Pesanan dari\nSatu Layar'), findsOneWidget);
      await _capture(tester, binding, '02-onboarding');
      await tester.ensureVisible(find.text('Lanjut'));
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await _capture(tester, binding, '03-login');
      await tester.ensureVisible(find.text('Login Dengan Google'));
      await _capture(tester, binding, '03b-login-options');
      await tester.tap(find.text('Login Dengan Google'));
      await tester.pumpAndSettle();
      expect(find.text('Login Google belum dikonfigurasi'), findsOneWidget);
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      await _capture(tester, binding, '04-register-akun');
      final email =
          'device-${DateTime.now().microsecondsSinceEpoch}@example.com';
      await tester.enterText(
        find.byKey(const Key('Nama Pemilik')),
        'Pemilik Perangkat',
      );
      await tester.enterText(
        find.byKey(const Key('Nama Toko')),
        'Toko Uji Perangkat',
      );
      await tester.enterText(find.byKey(const Key('email')), email);
      await tester.enterText(
        find.byKey(const Key('Kata Sandi')),
        'SandiUji123!',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await _waitFor(tester, find.text('Kategori Toko'));
      await tester.tap(find.text('Sembako'));
      await tester.tap(find.text('Sayur'));
      await _capture(tester, binding, '05-register-info-toko');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Jarak antar maksimal: 5 km'), findsOneWidget);
      await _capture(tester, binding, '06-register-pengiriman');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Toko Kamu Sudah Terdaftar'), findsOneWidget);
      await _capture(tester, binding, '07-register-sukses');
      await tester.ensureVisible(find.text('+ Tambah Produk'));
      await tester.tap(find.text('+ Tambah Produk'));
      await tester.pumpAndSettle();
      expect(find.text('Selamat datang, Toko Uji Perangkat'), findsOneWidget);
      await _capture(tester, binding, '08-home');
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), email);
      await tester.enterText(
        find.byKey(const Key('Kata Sandi')),
        'SandiUji123!',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await _waitFor(tester, find.text('Selamat datang, Toko Uji Perangkat'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await bootstrap('dev');
      await tester.pump(const Duration(seconds: 3));
      await _waitFor(tester, find.text('Selamat datang, Toko Uji Perangkat'));
      expect(find.text('Login ke Toko'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

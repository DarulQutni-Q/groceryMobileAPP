import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/bootstrap.dart';
import 'package:gardenmart_customer/features/auth/presentation/reset_pages.dart';
import 'package:grocery_shared/shared.dart';
import 'package:integration_test/integration_test.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  expect(finder, findsOneWidget);
}

Future<void> tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'customer registers with phone, restores, logs out and logs in by phone',
    (tester) async {
      final storage = SecureStorage();
      await storage.clearSession();
      await storage.setRememberSession(true);
      await bootstrap('dev');
      await tester.pump();
      await binding.convertFlutterSurfaceToImage();
      await waitFor(tester, find.text('Get Started'));
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot(name);
      }

      await capture('01-splash');
      await tap(tester, 'Get Started');
      await capture('02-login');
      await tap(tester, 'Lupa Kata Sandi?');
      await capture('04-forgot-password');
      await tester.enterText(
        find.byKey(const Key('reset-email')),
        'pembeli@example.com',
      );
      await tap(tester, 'Send Email');
      await waitFor(tester, find.text('Segera hadir'));
      expect(find.text('Email Reset Sent!'), findsNothing);
      final resetContext = tester.element(find.byType(ResetPage));
      ScaffoldMessenger.of(resetContext).hideCurrentSnackBar();
      Navigator.of(resetContext).pushNamed('/email-sent');
      await tester.pumpAndSettle();
      await capture('05-email-sent-preview');
      Navigator.of(tester.element(find.byType(ResetPage).last)).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(ResetPage))).pop();
      await tester.pumpAndSettle();
      await tap(tester, 'Daftar Akun Baru');
      await capture('03-register-phone');
      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final email = 'b1device$suffix@example.com';
      final phone = '081${suffix.substring(suffix.length - 9)}';
      const password = 'SandiDevice123!';
      for (final entry in {
        'register-email': email,
        'register-phone': phone,
        'register-password': password,
        'register-confirm': password,
      }.entries) {
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, 'Daftar');
      final greeting = find.text('Selamat pagi, ${email.split('@').first}');
      await waitFor(tester, greeting);
      await capture('06-home-registered');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await bootstrap('dev');
      await waitFor(tester, greeting);
      await capture('07-session-restored');
      await tap(tester, 'Keluar');
      await waitFor(tester, find.text('Get Started'));
      expect(await storage.readRefreshToken(), isNull);
      await tap(tester, 'Get Started');
      await tester.enterText(find.byKey(const Key('login-identity')), phone);
      await tester.enterText(find.byKey(const Key('login-password')), password);
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, 'Masuk Sekarang');
      await waitFor(tester, greeting);
      await capture('08-phone-login');
      final profile = await AuthApi(
        ApiClient(baseUrl: 'http://10.0.2.2:8000', storage: storage),
      ).getMe();
      expect(profile.role, 'customer');
      expect(profile.phone, '+62${phone.substring(1)}');
      expect(tester.takeException(), isNull);
    },
  );
}

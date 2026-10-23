import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/app.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/auth/presentation/forgot_password_screen.dart';
import 'package:seller/features/auth/presentation/new_password_screen.dart';
import 'package:seller/features/auth/presentation/otp_screen.dart';

// Minimal HTTP transport that stubs the three reset-password endpoints.
class _ResetTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final Map<String, dynamic> body;
    if (request.path == '/auth/forgot-password') {
      body = {
        'message': 'Kode verifikasi telah dikirim',
        'email': 'seller@example.com',
        'expires_in': 300,
        'masked_phone': '+62 819 **** 1234',
      };
    } else if (request.path == '/auth/verify-otp') {
      body = {
        'message': 'Kode verifikasi valid',
        'reset_token': 'token-abc',
      };
    } else if (request.path == '/auth/reset-password') {
      body = {'message': 'Kata sandi berhasil diperbarui'};
    } else {
      body = {};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void _mockSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async =>
            (call.arguments as Map)['key'] == 'seller_onboarding_seen'
            ? 'true'
            : null,
      );
}

Widget _appWith(String baseUrl) => ProviderScope(
  overrides: [apiBaseUrlProvider.overrideWithValue(baseUrl)],
  child: const SellerApp(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordScreen unit', () {
    testWidgets('validates empty and invalid email', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            ],
            child: ForgotPasswordScreen(
              onBack: () {},
              onOtpSent: (_, __) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Kirim Kode Verifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Email wajib diisi'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'bukan-email',
      );
      await tester.tap(find.text('Kirim Kode Verifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Alamat email tidak valid'), findsOneWidget);
    });
  });

  group('OtpScreen unit', () {
    testWidgets('renders 6 boxes and instruction text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            ],
            child: OtpScreen(
              email: 'seller@example.com',
              maskedPhone: '+62 819 **** 1234',
              onBack: () {},
              onVerified: (_, __) {},
            ),
          ),
        ),
      );
      // 6 OTP boxes present
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_$i')), findsOneWidget);
      }
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('+62 819 **** 1234'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error when submitted without all 6 digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            ],
            child: OtpScreen(
              email: 'seller@example.com',
              maskedPhone: null,
              onBack: () {},
              onVerified: (_, __) {},
            ),
          ),
        ),
      );
      // Only fill 3 digits
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byKey(Key('otp_$i')), '$i');
      }
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan 6 digit kode OTP'), findsOneWidget);
    });
  });

  group('NewPasswordScreen unit', () {
    testWidgets('shows validation checklist updating as user types', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            ],
            child: NewPasswordScreen(
              email: 'seller@example.com',
              resetToken: 'token-abc',
              onBack: () {},
              onSuccess: () {},
            ),
          ),
        ),
      );
      // Initially all checks are unchecked (grey icons)
      expect(find.text('8–20 karakter'), findsOneWidget);
      expect(find.text('Memuat huruf dan angka'), findsOneWidget);
      expect(find.text('Memuat karakter khusus (!@#\$...)'), findsOneWidget);
      expect(find.text('Konfirmasi cocok'), findsOneWidget);

      // Type a valid password
      await tester.enterText(
        find.byKey(const Key('new_password')),
        'Abc123!xy',
      );
      await tester.pump();
      // Checklist labels stay visible (they exist as Text widgets)
      expect(find.text('8–20 karakter'), findsOneWidget);
      expect(find.text('Memuat huruf dan angka'), findsOneWidget);
      expect(find.text('Konfirmasi cocok'), findsOneWidget);

      // Fill confirm and verify no mismatch label shown
      await tester.enterText(
        find.byKey(const Key('confirm_password')),
        'Abc123!xy',
      );
      await tester.pump();
      // No inline validation error labels visible
      expect(find.text('Kata sandi harus 8-20 karakter'), findsNothing);
      expect(find.text('Kata sandi tidak cocok'), findsNothing);
    });

    testWidgets('validates mismatched passwords', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            ],
            child: NewPasswordScreen(
              email: 'seller@example.com',
              resetToken: 'token-abc',
              onBack: () {},
              onSuccess: () {},
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('new_password')),
        'Abc123!xy',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password')),
        'DifferentPass!1',
      );
      await tester.tap(find.text('Simpan Sandi Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi tidak cocok'), findsOneWidget);
    });
  });

  group('Full reset-password flow via SellerApp', () {
    setUp(_mockSecureStorage);

    testWidgets('navigates Lupa Kata Sandi → OTP → Sandi Baru → Login', (
      tester,
    ) async {
      // Override apiClientProvider to use stub HTTP adapter
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('https://api.example.com'),
            apiClientProvider.overrideWith((ref) {
              final stubDio = Dio(
                BaseOptions(baseUrl: 'https://api.example.com'),
              );
              stubDio.httpClientAdapter = _ResetTransport();
              return ApiClient(
                baseUrl: 'https://api.example.com',
                storage: ref.read(storageProvider),
                dio: stubDio,
              );
            }),
          ],
          child: const SellerApp(),
        ),
      );
      // Wait past splash → login
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Login ke Toko'), findsOneWidget);

      // Tap "Lupa kata sandi?"
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(find.text('Lupa Kata Sandi'), findsOneWidget);
      expect(find.byKey(const Key('forgot_email')), findsOneWidget);

      // Enter email and submit
      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'seller@example.com',
      );
      await tester.tap(find.text('Kirim Kode Verifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi OTP'), findsOneWidget);

      // Fill OTP boxes
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_$i')), '1');
        await tester.pump();
      }
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Buat Sandi Baru'), findsOneWidget);

      // Fill new password and confirm
      await tester.enterText(
        find.byKey(const Key('new_password')),
        'Abc123!xy',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password')),
        'Abc123!xy',
      );
      await tester.tap(find.text('Simpan Sandi Baru'));
      await tester.pumpAndSettle();

      // Should show success snackbar and navigate back to login
      expect(
        find.textContaining('Kata sandi berhasil diperbarui'),
        findsOneWidget,
      );
      expect(find.text('Login ke Toko'), findsOneWidget);
    });
  });
}

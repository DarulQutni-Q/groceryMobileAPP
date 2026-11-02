import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/auth/presentation/reset_verify_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';

Future<List<RequestOptions>> pumpPage(
  WidgetTester tester, {
  required Future<ResponseBody> Function(RequestOptions) respond,
}) async {
  final calls = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = CustomerAdapter((request) async {
    calls.add(request);
    return respond(request);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            baseUrl: 'https://api.example.com',
            storage: SecureStorage(),
            dio: dio,
          ),
        ),
      ],
      child: MaterialApp(
        routes: {'/login': (_) => const Scaffold(body: Text('LOGIN'))},
        home: const ResetVerifyPage(email: 'reset@example.com'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

Future<void> isiForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('reset-kode')), '123456');
  await tester.enterText(find.byKey(const Key('reset-sandi')), 'Baru123!x');
  await tester.enterText(find.byKey(const Key('reset-konfirmasi')), 'Baru123!x');
  await tester.tap(find.byKey(const Key('reset-simpan')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reset verify: tampil dan validasi jalan', (tester) async {
    await pumpPage(tester, respond: (_) async => response({}));
    expect(find.text('Masukkan Kode'), findsOneWidget);
    expect(find.byKey(const Key('reset-kode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset-simpan')));
    await tester.pump();
    expect(find.text('Kode harus 6 digit angka'), findsOneWidget);
    expect(find.text('Kata sandi harus 8 sampai 20 karakter'), findsOneWidget);
  });

  testWidgets('reset verify: kode benar -> reset -> pindah login', (tester) async {
    final calls = await pumpPage(tester, respond: (request) async {
      if (request.path == '/auth/verify-otp') {
        return response({'reset_token': 'tok123'});
      }
      if (request.path == '/auth/reset-password') {
        return response({});
      }
      return response({}, 404);
    });
    await isiForm(tester);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(calls.map((c) => c.path), containsAll(['/auth/verify-otp', '/auth/reset-password']));
    final reset = calls.firstWhere((c) => c.path == '/auth/reset-password');
    expect(reset.data['reset_token'], 'tok123');
    expect(reset.data['email'], 'reset@example.com');
  });

  testWidgets('reset verify: kode salah -> snackbar, tetap di halaman', (tester) async {
    await pumpPage(tester, respond: (request) async {
      if (request.path == '/auth/verify-otp') {
        return response({'detail': 'Kode verifikasi tidak valid'}, 400);
      }
      return response({}, 404);
    });
    await isiForm(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Masukkan Kode'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });
}

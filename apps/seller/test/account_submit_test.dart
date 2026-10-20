import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/core/seller_theme.dart';
import 'package:seller/features/auth/application/auth_provider.dart';
import 'package:seller/features/auth/presentation/account_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final register in [false, true]) {
    testWidgets(
      '${register ? 'register' : 'login'} ignores Enter while submitting',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel(
                'plugins.it_nomads.com/flutter_secure_storage',
              ),
              (_) async => null,
            );
        final pending = Completer<void>();
        var submissions = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) async {
              if (request.path == '/auth/me') {
                handler.resolve(
                  Response(
                    requestOptions: request,
                    data: {
                      'id': 'u1',
                      'nama': 'Pemilik Uji',
                      'email': 'uji@example.com',
                      'role': 'seller',
                      'nama_toko': 'Toko Uji',
                    },
                  ),
                );
              } else {
                submissions++;
                await pending.future;
                handler.resolve(
                  Response(
                    requestOptions: request,
                    data: {
                      'access_token': 'access',
                      'refresh_token': 'refresh',
                    },
                  ),
                );
              }
            },
          ),
        );
        final api = ApiClient(
          baseUrl: dio.options.baseUrl,
          storage: SecureStorage(),
          dio: dio,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiClientProvider.overrideWithValue(api)],
            child: MaterialApp(
              theme: sellerTheme(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AccountForm(register: register),
                ),
              ),
            ),
          ),
        );
        if (register) {
          await tester.enterText(
            find.byKey(const Key('Nama Pemilik')),
            'Pemilik Uji',
          );
          await tester.enterText(
            find.byKey(const Key('Nama Toko')),
            'Toko Uji',
          );
        }
        await tester.enterText(
          find.byKey(const Key('email')),
          'uji@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('Kata Sandi')),
          'SandiUji123!',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(submissions, 1);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Memproses...'),
        );
        expect(button.onPressed, isNull);
        await tester.showKeyboard(find.byKey(const Key('Kata Sandi')));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        final sentWhileBusy = submissions;
        pending.complete();
        await tester.pumpAndSettle();
        expect(sentWhileBusy, 1);
        expect(submissions, 1);
        expect(tester.takeException(), isNull);
        dio.close();
      },
    );
  }
}

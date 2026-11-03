import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/auth/presentation/auth_page.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('judul kartu mengikuti tab masuk/daftar', (tester) async {
    final fixture = AuthFixture()..installStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const AuthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk Akun Pembeli'), findsOneWidget);

    await tester.tap(find.text('Daftar Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Akun Pembeli'), findsOneWidget);
    expect(find.text('Masuk Akun Pembeli'), findsNothing);

    await tester.tap(find.text('Masuk Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk Akun Pembeli'), findsOneWidget);
  });
}

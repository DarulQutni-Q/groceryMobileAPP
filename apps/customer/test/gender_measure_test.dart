import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/ubah_profil_page.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);
  // Regresi untuk "tombol hitam jenis kelamin kekecilan": Row tanpa
  // crossAxisAlignment.stretch membuat pil setinggi konten (19px di
  // kontrol 46px). Pil harus mengisi penuh tinggi dalam kontrol
  // (46 - border 1x2 - padding 2x2 = 40) dan setengah lebarnya.
  testWidgets('pil jenis kelamin mengisi penuh kontrol', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fixture = AuthFixture();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://localhost'),
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const UbahProfilPage(),
        ),
      ),
    );
    await tester.pump();
    final controlFinder = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border != null,
    );
    expect(controlFinder, findsOneWidget);
    final pill = find.descendant(
      of: controlFinder,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == gardenInk,
      ),
    );
    expect(pill, findsOneWidget);
    final pillRect = tester.getRect(pill);
    final controlRect = tester.getRect(controlFinder);
    expect(pillRect.height, controlRect.height - 6);
    expect(pillRect.width, (controlRect.width - 6) / 2);
    expect(pillRect.top - controlRect.top, 3);
    expect(pillRect.left - controlRect.left, 3);
  });
}

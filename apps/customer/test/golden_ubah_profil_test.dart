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

  testWidgets('golden ubah profil', (tester) async {
    // Halaman kini ConsumerWidget: sediakan ProviderScope + prefs kosong
    // supaya field tampil kosong seperti sebelum diubah.
    SharedPreferences.setMockInitialValues({});
    // Auth tanpa token (storage kosong): halaman tampil kosong seperti golden
    // lama, tanpa memanggil API_BASE_URL yang tidak ada di tes.
    final fixture = AuthFixture();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
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
    expect(find.text('Ubah Profil & Identitas'), findsOneWidget);
    expect(find.text('Perempuan'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ubah_profil.png'),
    );
  });
}

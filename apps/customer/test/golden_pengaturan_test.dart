import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/garden_widgets.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pengaturan_page.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden pengaturan', (tester) async {
    // Halaman kini baca SharedPreferences (PIN, cache): mock agar tidak
    // memanggil channel platform yang tidak ada di tester.
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: authBackground,
          body: const SafeArea(child: PengaturanPage()),
          bottomNavigationBar: GardenBottomNav(
            index: 4,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Ubah Profil & Identitas'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pengaturan.png'),
    );
  });
}

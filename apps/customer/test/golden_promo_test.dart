import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/garden_widgets.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/promo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(() async {
    await loadTestFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('golden promo', (tester) async {
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
          body: const SafeArea(child: PromoPage()),
          bottomNavigationBar: GardenBottomNav(index: 1, onSelect: (_) {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Promo & Kupon'), findsOneWidget);
    expect(find.text('Promo Mingguan'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/promo.png'),
    );
  });
}

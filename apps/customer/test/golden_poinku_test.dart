import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/poinku_page.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden poinku', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: const PoinkuPage(),
      ),
    );
    await tester.pump();
    expect(find.text('All Rewards'), findsOneWidget);
    expect(find.text('Tukar'), findsNWidgets(2));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/poinku.png'),
    );
  });
}

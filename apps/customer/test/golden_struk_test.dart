import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/checkout/presentation/struk_page.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden struk', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: const StrukPage(),
      ),
    );
    // Dekode gambar aset logo butuh runAsync seperti di golden_test.dart.
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('GARDENMART SUPERMARKET'), findsOneWidget);
    expect(find.text('TOTAL BAYAR'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/struk.png'),
    );
  });
}

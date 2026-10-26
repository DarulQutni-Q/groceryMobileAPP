import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/garden_widgets.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pesanan_page.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden pesanan saya', (tester) async {
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
          body: const SafeArea(child: PesananPage()),
          bottomNavigationBar: GardenBottomNav(
            index: 3,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Pesanan Saya'), findsOneWidget);
    expect(find.text('Riwayat Pesanan'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pesanan.png'),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;
import 'pesanan_fixture.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden chat driver', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Pesanan fixture diantar (GM-1001, Rp 67.600): golden memverifikasi
    // layout lengkap dengan kartu pesanan dan pesan sistem.
    final order = pesananFixture().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: ChatDriverPage(order: order),
      ),
    );
    await tester.pump();
    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.text('Pesanan #GM-1001'), findsOneWidget);
    expect(find.text('Pesanan dalam perjalanan • Rp 67.600'), findsOneWidget);
    expect(find.text('Pesanan telah diserahkan ke Kurir Toko'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chat_driver.png'),
    );
  });
}

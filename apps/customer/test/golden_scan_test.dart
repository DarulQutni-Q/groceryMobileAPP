import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/scan_qr_page.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden scan qr', (tester) async {
    // Kamera asli tidak ada di test: bungkam channel scanner supaya
    // dispose controller tidak melempar MissingPluginException.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/event'),
      (call) async => null,
    );
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const ScanQrPage(),
        ),
      ),
    );
    await tester.pump();
    // Satu frame lagi supaya callback pasca-frame errorBuilder sempat jalan
    // dan garis scan tersembunyi sebelum golden diambil.
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scan.png'),
    );
  });
}

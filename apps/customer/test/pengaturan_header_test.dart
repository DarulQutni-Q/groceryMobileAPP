import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pengaturan_page.dart';

import 'golden_test.dart' show loadTestFonts;

/// Regresi untuk "teks Pengaturan tertimpa kurva header": di HP, SafeArea
/// status bar mendorong baris judul ke bawah sampai menyentuh gelombang
/// (header lama 104px + topPadding 38). Judul + tombol kembali harus
/// berakhir di atas tepi gelombang (tinggi header 120 - kedalaman 28 = 92).
void main() {
  setUpAll(loadTestFonts);

  Future<void> pumpHeader(WidgetTester tester, double statusBar) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: statusBar)),
          child: const Scaffold(body: PengaturanPage()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('judul tidak tertimpa gelombang (status bar 24)', (
    tester,
  ) async {
    await pumpHeader(tester, 24);
    final titleRect = tester.getRect(find.text('Pengaturan'));
    expect(titleRect.bottom, lessThan(92));
    final backRect = tester.getRect(find.byIcon(Icons.arrow_back));
    expect(backRect.bottom, lessThan(92));
  });

  testWidgets('judul tidak tertimpa gelombang (status bar 33)', (
    tester,
  ) async {
    await pumpHeader(tester, 33);
    final titleRect = tester.getRect(find.text('Pengaturan'));
    expect(titleRect.bottom, lessThan(92));
    final backRect = tester.getRect(find.byIcon(Icons.arrow_back));
    expect(backRect.bottom, lessThan(92));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/checkout/presentation/metode_pembayaran_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('halaman metode hanya menampilkan metode asli yang didukung', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: const MetodePembayaranPage(),
      ),
    );
    await tester.pumpAndSettle();
    // Catatan di atas daftar: dicek sebelum scroll (nanti keluar layar).
    expect(
      find.textContaining('Belum ada dompet atau kartu yang terhubung'),
      findsOneWidget,
    );
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('ShopeePay'), findsOneWidget);
    expect(find.text('VA BCA'), findsOneWidget);
    expect(find.text('VA BRI'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('VA Mandiri'),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('VA Mandiri'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('COD (Bayar di Tempat)'),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('COD (Bayar di Tempat)'), findsOneWidget);
    expect(find.text('DOMPET DIGITAL TERHUBUNG'), findsNothing);
    expect(find.text('KARTU DEBIT & KREDIT'), findsNothing);
  });

  testWidgets('memilih metode lalu simpan menyimpan preferensi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: const MetodePembayaranPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('metode-cod')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metode-cod')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('metode_bayar_preferensi'), 'cod');
  });
}

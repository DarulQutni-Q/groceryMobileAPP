import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/checkout/application/placeholder_metode.dart';
import 'package:gardenmart_customer/features/checkout/presentation/metode_pembayaran_page.dart';

import 'golden_test.dart' show loadTestFonts;

/// Pompa halaman lewat tombol, supaya Simpan bisa pop kembali ke harness.
/// Viewport tinggi (844 logis) supaya tombol Simpan di bawah tidak
/// terpotong lipatan.
Future<void> _pompa(WidgetTester tester) async {
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
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const MetodePembayaranPage(),
                ),
              ),
              child: const Text('Ke Metode'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ke Metode'));
  await tester.pumpAndSettle();
}

bool _radioSelected(WidgetTester tester, String key) {
  final widget = tester.widget(find.byKey(Key(key)));
  return (widget as dynamic).selected as bool;
}

bool _toggleValue(WidgetTester tester) {
  final widget = tester.widget(find.byKey(const Key('toggle-biometrik')));
  return (widget as dynamic).value as bool;
}

void main() {
  setUpAll(loadTestFonts);

  test('placeholder: data demo sesuai referensi, bukan data asli', () {
    expect(placeholderDompet[0].nama, 'Saldo GoPay');
    expect(placeholderDompet[0].status, 'Rp 445.200');
    expect(placeholderDompet[0].terhubung, isTrue);
    expect(placeholderDompet[1].nama, 'ShopeePay');
    expect(placeholderDompet[1].status, 'Belum Terhubung');
    expect(placeholderDompet[1].terhubung, isFalse);
    expect(placeholderKartu[0].judul, 'BCA Mastercard Debit');
    expect(placeholderKartu[0].tersamar, contains('4122'));
    expect(placeholderKartu[0].utama, isTrue);
    expect(placeholderKartu[0].metodeBayar, 'va_bca');
    expect(placeholderKartu[1].judul, 'Mandiri Visa Debit');
    expect(placeholderKartu[1].tersamar, contains('8921'));
    expect(placeholderKartu[1].utama, isFalse);
    expect(placeholderKartu[1].metodeBayar, 'va_mandiri');
    expect(metodeBayarDariKartu(0), 'va_bca');
    expect(metodeBayarDariKartu(1), 'va_mandiri');
    expect(metodeBayarDariKartu(-1), isNull);
    expect(metodeBayarDariKartu(99), isNull);
  });

  testWidgets('radio: ketuk memilih satu dan membatalkan yang lain',
      (tester) async {
    await _pompa(tester);
    await tester.tap(find.byKey(const Key('metode-mandiri')));
    await tester.pump();
    expect(_radioSelected(tester, 'metode-mandiri'), isTrue);
    expect(_radioSelected(tester, 'metode-bca'), isFalse);
    await tester.tap(find.byKey(const Key('metode-bca')));
    await tester.pump();
    expect(_radioSelected(tester, 'metode-bca'), isTrue);
    expect(_radioSelected(tester, 'metode-mandiri'), isFalse);
  });

  testWidgets('simpan: pilihan + preferensi tersimpan, kembali ke layar awal',
      (tester) async {
    await _pompa(tester);
    await tester.tap(find.byKey(const Key('metode-mandiri')));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Ke Metode'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('metode_utama'), 1);
    expect(prefs.getString('metode_bayar_preferensi'), 'va_mandiri');
  });

  testWidgets('biometrik: toggle membalik dan tersimpan', (tester) async {
    await _pompa(tester);
    final sebelum = _toggleValue(tester);
    await tester.tap(find.byKey(const Key('toggle-biometrik')));
    await tester.pump();
    expect(_toggleValue(tester), isNot(sebelum));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('metode_biometrik'), isNot(sebelum));
  });

  testWidgets('top up dan hubungkan: dialog jujur, tanpa mengubah apa pun',
      (tester) async {
    await _pompa(tester);
    await tester.tap(find.text('Top Up'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Top Up GoPay belum tersedia di GardenMart '
        'karena belum ada integrasi e-wallet di backend.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hubungkan'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Menghubungkan ShopeePay belum tersedia di GardenMart '
        'karena belum ada integrasi e-wallet di backend.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(MetodePembayaranPage), findsOneWidget);
  });
}

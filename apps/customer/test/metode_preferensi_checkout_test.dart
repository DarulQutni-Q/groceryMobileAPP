import 'package:flutter_test/flutter_test.dart';

import 'checkout_konfirmasi_test.dart' show bukaKonfirmasi;
import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  // Satu-satunya tes di file ini, sengaja: preferensi mock harus
  // dipasang lewat bukaKonfirmasi, sebelum instance prefs pertama
  // dibuat di proses ini.
  testWidgets('checkout baru memakai metode utama yang disimpan',
      (tester) async {
    await bukaKonfirmasi(tester, prefsAwal: {
      'metode_bayar_preferensi': 'va_mandiri',
    });
    expect(find.text('VA Mandiri'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'golden_test.dart' show loadTestFonts;

/// Putaran 2 loop bandingin, layar login saja:
/// 1. ikon orang di field identitas harus nampak (ukuran + warna eksplisit,
///    sama seperti treatment ikon mata di field kata sandi);
/// 2. pill atas jadi tab Masuk Akun / Daftar Akun, tap beralih form dan
///    tab aktif jadi gelap sementara yang lain transparan.
void main() {
  setUpAll(loadTestFonts);

  Future<void> openLogin(WidgetTester tester) async {
    final fixture = AuthFixture()..installStorage();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          googleTokenProvider.overrideWithValue(() async => 'google-token'),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  }

  /// Warna Material terdekat di atas teks tab (Material milik tab itu).
  Color? tabColor(WidgetTester tester, String label) {
    final element = tester.element(find.text(label));
    Color? result;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Material) {
        result = widget.color;
        return false;
      }
      return true;
    });
    return result;
  }

  testWidgets('ikon orang nampak dengan warna dan ukuran eksplisit',
      (tester) async {
    await openLogin(tester);
    final iconFinder = find.byIcon(Icons.person_outline);
    expect(iconFinder, findsOneWidget);
    final icon = tester.widget<Icon>(iconFinder);
    expect(icon.size, 24);
    expect(icon.color, const Color(0xFF515951));
  });

  testWidgets('tab beralih form dan warna aktif ikut berpindah',
      (tester) async {
    await openLogin(tester);

    // Awal: tab Masuk aktif (gelap), Daftar nonaktif (transparan).
    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(tabColor(tester, 'Masuk Akun'), gardenInk);
    expect(tabColor(tester, 'Daftar Akun'), Colors.transparent);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('Daftar Akun Baru'), findsOneWidget);

    // Pindah ke Daftar: form daftar tampil, form login hilang, warna ikut.
    await tester.tap(find.text('Daftar Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Verifikasi kata sandi'), findsOneWidget);
    expect(find.text('Nomor Handphone (opsional)'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsNothing);
    expect(find.text('Ingat Saya'), findsNothing);
    expect(tabColor(tester, 'Daftar Akun'), gardenInk);
    expect(tabColor(tester, 'Masuk Akun'), Colors.transparent);

    // Kembali ke Masuk: form login tampil lagi, warna kembali.
    await tester.tap(find.text('Masuk Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk Sekarang'), findsOneWidget);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('Daftar'), findsNothing);
    expect(tabColor(tester, 'Masuk Akun'), gardenInk);
    expect(tabColor(tester, 'Daftar Akun'), Colors.transparent);
  });

  testWidgets('route daftar membuka tab Daftar sejak awal', (tester) async {
    final fixture = AuthFixture()..installStorage();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          googleTokenProvider.overrideWithValue(() async => 'google-token'),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar Akun Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar'), findsOneWidget);
    expect(tabColor(tester, 'Daftar Akun'), gardenInk);
    expect(tabColor(tester, 'Masuk Akun'), Colors.transparent);
  });
}

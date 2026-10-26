import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/app.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';

import 'auth_state_test.dart' show AuthFixture;

/// Loop verifikasi visual: tiap test merender satu screen ke PNG
/// (test/goldens/*.png) untuk dibandingkan dengan referensi Figma.
/// Font asli dimuat supaya metrik teks sama dengan device:
/// Roboto dari cache Flutter, GardenSerif dari aset app.
Future<void> loadTestFonts() async {
  final roboto = FontLoader('Roboto');
  final dir = Directory(
    '/home/ubuntu/flutter/bin/cache/artifacts/material_fonts',
  );
  // Semua varian Roboto (tanpa Condensed) supaya fallback weight jalan
  // dan teks tidak jatuh ke font Ahem (kotak-kotak).
  for (final entry in dir.listSync()) {
    final name = entry.path.split('/').last;
    if (!name.startsWith('Roboto-') || name.contains('Condensed')) continue;
    if (!name.endsWith('.ttf')) continue;
    final bytes = await File(entry.path).readAsBytes();
    roboto.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await roboto.load();

  // Ikon Material tidak ikut ter-load di widget test; muat manual.
  final icons = FontLoader('MaterialIcons');
  final iconFile = File('${dir.path}/MaterialIcons-Regular.otf');
  final iconBytes = await iconFile.readAsBytes();
  icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await icons.load();

  final serif = FontLoader('GardenSerif');
  serif.addFont(rootBundle.load('assets/fonts/LiberationSerif-Regular.ttf'));
  serif.addFont(rootBundle.load('assets/fonts/LiberationSerif-Bold.ttf'));
  await serif.load();
}

void main() {
  setUpAll(loadTestFonts);

  /// Dekode gambar aset di widget test butuh runAsync; tanpa ini
  /// RawImage.image tetap null dan golden jadi kosong.
  Future<void> settleImages(WidgetTester tester) async {
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openApp(WidgetTester tester) async {
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
    await settleImages(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await settleImages(tester);
  }

  testWidgets('golden splash onboarding', (tester) async {
    await openApp(tester);
    expect(find.text('Get Started'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/splash.png'),
    );
  });

  testWidgets('golden login', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('Get Started'));
    expect(find.text('Masuk Sekarang'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('golden register', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Daftar Akun Baru'));
    expect(find.text('Daftar'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/register.png'),
    );
  });

  testWidgets('golden forgot password', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Lupa Kata Sandi?'));
    expect(find.text('Forget Password'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/forgot.png'),
    );
  });

  testWidgets('golden email sent', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('Get Started'));
    await tap(tester, find.text('Lupa Kata Sandi?'));
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'pembeli@example.com',
    );
    await tap(tester, find.text('Send Email'));
    expect(find.text('Email Reset Sent!'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/email_sent.png'),
    );
  });
}

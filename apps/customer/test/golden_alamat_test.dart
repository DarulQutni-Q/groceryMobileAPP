import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/alamat_page.dart';
import 'package:grocery_shared/shared.dart';

import 'golden_test.dart' show loadTestFonts;

void main() {
  setUpAll(loadTestFonts);

  testWidgets('golden alamat pengiriman', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alamatProvider.overrideWithValue(
            const AsyncValue.data([
              Alamat(
                id: 'a1',
                label: 'Rumah',
                namaPenerima: 'Darul Qutni',
                noHp: '+62 812-8899-2122',
                alamatLengkap:
                    'Jl. Mudi Mesra, Kandang, Kec. Samalanga, Kota Bireuen, Aceh 24264',
                patokan: 'Pagar hitam no. 42, Titip di meja teras.',
                isUtama: true,
              ),
              Alamat(
                id: 'a2',
                label: 'Keluarga',
                namaPenerima: 'Ibu Maryam (Ortu)',
                noHp: '+62 813-7722-9901',
                alamatLengkap:
                    'Komplek Taman Setiabudi Indah Blok B-12, Kec. Medan Selayang, Kota Medan 20132',
                isUtama: false,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: const AlamatPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Pinpoint Lokasi GPS Pengantaran'), findsOneWidget);
    expect(find.text('Ubah Alamat'), findsNWidgets(2));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/alamat.png'),
    );
  });
}

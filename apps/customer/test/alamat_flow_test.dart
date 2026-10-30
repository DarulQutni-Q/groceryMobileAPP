import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/alamat_page.dart';

import 'auth_state_test.dart';

void main() {
  testWidgets('customer creates an address and selects the persisted primary', (
    tester,
  ) async {
    // Viewport tinggi: formulir baru (peta + field) lebih tinggi dari
    // viewport default, field bawah lipatan tidak ter-build tanpa ini.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = AuthFixture()..installStorage();
    final entries = <Map<String, dynamic>>[];
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      fixture.calls.add(request);
      if (request.method == 'POST') {
        entries.add({
          'id': 'a1',
          ...Map<String, dynamic>.from(request.data as Map),
          'is_utama': true,
        });
        return response(entries.single, 201);
      }
      return response(entries);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(fixture.api.client)],
        child: const MaterialApp(home: AlamatPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
    await tester.tap(find.text('Tambah Alamat Baru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('alamat-nama')), 'Pembeli');
    await tester.enterText(find.byKey(const Key('alamat-hp')), '081234567890');
    await tester.enterText(
      find.byKey(const Key('alamat-lengkap')),
      'Jalan Melati 10',
    );
    await tester.ensureVisible(find.text('Simpan Alamat'));
    await tester.tap(find.text('Simpan Alamat'));
    await tester.pumpAndSettle();
    expect(find.text('Pembeli'), findsOneWidget);
    expect(find.text('Utama'), findsOneWidget);
    expect(entries.single['alamat_lengkap'], 'Jalan Melati 10');
    expect(tester.takeException(), isNull);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/notifications_page.dart';

import 'auth_state_test.dart' show AuthFixture, CustomerAdapter, response;

void main() {
  late AuthFixture fixture;
  late List<RequestOptions> calls;

  Future<void> open(
    WidgetTester tester, {
    required List<Map<String, dynamic>> rows,
    required int belumDibaca,
  }) async {
    fixture = AuthFixture()..installStorage();
    calls = [];
    var data = List<Map<String, dynamic>>.from(rows);
    var belum = belumDibaca;
    fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
      calls.add(request);
      if (request.path == '/notifikasi' && request.method == 'GET') {
        return response({'data': data, 'belum_dibaca': belum});
      }
      if (request.path == '/notifikasi/baca-semua' &&
          request.method == 'PATCH') {
        data = data
            .map((row) => {...row, 'dibaca': true})
            .toList();
        belum = 0;
        return response({'dibaca': 1});
      }
      if (request.path.endsWith('/baca') && request.method == 'PATCH') {
        final id = request.path.split('/')[2];
        data = data
            .map((row) => row['id'] == id ? {...row, 'dibaca': true} : row)
            .toList();
        belum = 0;
        return response(
          data.firstWhere((row) => row['id'] == id),
        );
      }
      return response({}, 404);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fixture.api.client),
        ],
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> row(
    String id,
    String judul,
    String isi,
    bool dibaca,
  ) =>
      {
        'id': id,
        'judul': judul,
        'isi': isi,
        'pesanan_id': 'o-1',
        'dibaca': dibaca,
        'created_at': '2026-11-02T10:00:00Z',
      };

  testWidgets('daftar + tandai semua dibaca', (tester) async {
    await open(
      tester,
      rows: [
        row('n-1', 'Pesanan DG-10001', 'Status pesananmu kini: Diproses', false),
        row('n-2', 'Pesanan DG-10000', 'Status pesananmu kini: Selesai', true),
      ],
      belumDibaca: 1,
    );
    expect(find.text('Pesanan DG-10001'), findsOneWidget);
    expect(find.text('Pesanan DG-10000'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsOneWidget);
    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (c) => c.path == '/notifikasi/baca-semua' && c.method == 'PATCH',
      ),
      isTrue,
    );
    expect(find.text('Tandai semua dibaca'), findsNothing);
  });

  testWidgets('tap kartu menandai satu dibaca', (tester) async {
    await open(
      tester,
      rows: [
        row('n-1', 'Pesanan DG-10001', 'Status pesananmu kini: Diproses', false),
      ],
      belumDibaca: 1,
    );
    await tester.tap(find.text('Pesanan DG-10001'));
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (c) => c.path == '/notifikasi/n-1/baca' && c.method == 'PATCH',
      ),
      isTrue,
    );
    expect(find.text('Tandai semua dibaca'), findsNothing);
  });

  testWidgets('kosong menampilkan empty state', (tester) async {
    await open(tester, rows: [], belumDibaca: 0);
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsNothing);
  });
}

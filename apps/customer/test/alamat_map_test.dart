import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/alamat_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/peta_alamat.dart';
import 'package:latlong2/latlong.dart';

import 'auth_state_test.dart';

/// Mock API alamat: GET list, POST create, PUT update, PATCH jadikan-utama.
class _AlamatMock {
  _AlamatMock(this.entries);
  final List<Map<String, dynamic>> entries;
  final requests = <RequestOptions>[];

  Future<ResponseBody> handle(RequestOptions request) async {
    requests.add(request);
    final path = request.path;
    if (request.method == 'GET' && path == '/alamat') {
      return response(entries);
    }
    if (request.method == 'POST' && path == '/alamat') {
      final data = Map<String, dynamic>.from(request.data as Map);
      entries.add({'id': 'a${entries.length + 1}', ...data});
      return response(entries.last, 201);
    }
    if (request.method == 'PUT' && path.startsWith('/alamat/')) {
      final id = path.split('/').last;
      final data = Map<String, dynamic>.from(request.data as Map);
      final index = entries.indexWhere((e) => e['id'] == id);
      entries[index] = {...entries[index], ...data};
      return response(entries[index]);
    }
    if (request.method == 'PATCH' && path.endsWith('/jadikan-utama')) {
      final id = path.split('/')[2];
      for (final entry in entries) {
        entry['is_utama'] = entry['id'] == id;
      }
      return response(entries.firstWhere((e) => e['id'] == id));
    }
    return response({'detail': 'not found'}, 404);
  }
}

Future<void> _pumpAlamat(
  WidgetTester tester,
  AuthFixture fixture,
  _AlamatMock mock,
) async {
  fixture.api.client.dio.httpClientAdapter = CustomerAdapter(mock.handle);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fixture.api.client)],
      child: const MaterialApp(home: AlamatPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Viewport tinggi supaya seluruh formulir (peta + semua field) ter-build
/// sekaligus di tes: di viewport default 600px, field bawah lipatan tidak
/// ikut ter-build oleh ListView malas dan finder tidak menemukannya.
/// Ini cuma soal tes, bukan perilaku aplikasi (di HP user scroll).
void _tallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('peta menampilkan pin, tombol GPS, atribusi, dan koordinat',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetaAlamat(
            initial: const LatLng(-6.9, 107.6),
            gpsOverride: () async => const LatLng(-6.2, 106.8),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    expect(find.text('Gunakan Lokasi Saya'), findsOneWidget);
    // Atribusi Google Maps tampil native di device, bukan Text widget.
    expect(find.text('Lat: -6.900000, Lng: 107.600000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('peta-gps')));
    await tester.pumpAndSettle();
    expect(find.text('Lat: -6.200000, Lng: 106.800000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS gagal menampilkan pesan jujur, bukan lokasi palsu',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetaAlamat(
            initial: const LatLng(-6.9, 107.6),
            gpsOverride: () async => null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('peta-gps')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lokasi tidak tersedia'), findsOneWidget);
    expect(find.text('Lat: -6.900000, Lng: 107.600000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'form alamat punya placeholder tiap field dan menyimpan alamat tersusun',
      (tester) async {
    _tallViewport(tester);
    final fixture = AuthFixture()..installStorage();
    final mock = _AlamatMock([]);
    await _pumpAlamat(tester, fixture, mock);
    expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
    await tester.tap(find.text('Tambah Alamat Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Titik Peta GPS (opsional)'), findsOneWidget);
    expect(find.text('Gunakan Lokasi Saya'), findsOneWidget);
    expect(find.text('cth: Budi Santoso'), findsOneWidget);
    expect(find.text('cth: 081234567890'), findsOneWidget);
    expect(find.text('cth: Jl. Melati No. 10, RT 01/RW 02'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('alamat-nama')), 'Pembeli');
    await tester.enterText(
      find.byKey(const Key('alamat-hp')),
      '081234567890',
    );
    await tester.enterText(
      find.byKey(const Key('alamat-lengkap')),
      'Jalan Melati 10',
    );
    await tester.ensureVisible(find.byKey(const Key('alamat-keckota')));
    expect(find.text('cth: Kec. Sukajadi, Kota Bandung'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('alamat-keckota')),
      'Kec. Sukajadi, Kota Bandung',
    );
    await tester.ensureVisible(find.byKey(const Key('alamat-kodepos')));
    expect(find.text('cth: 40162'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('alamat-kodepos')), '40162');
    await tester.ensureVisible(find.byKey(const Key('alamat-patokan')));
    expect(
      find.text('cth: Rumah cat hijau, gerbang samping'),
      findsOneWidget,
    );
    await tester.tap(find.text('Simpan Alamat'));
    await tester.pumpAndSettle();
    expect(find.text('Pembeli'), findsOneWidget);
    expect(
      mock.entries.single['alamat_lengkap'],
      'Jalan Melati 10, Kec. Sukajadi, Kota Bandung 40162',
    );
    // Tanpa sentuhan peta, tidak ada titik yang dikirim (bukan titik default palsu).
    expect(mock.entries.single['latitude'], isNull);
    expect(mock.entries.single['longitude'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pilih Alamat memindah pilihan utama', (tester) async {
    _tallViewport(tester);
    final fixture = AuthFixture()..installStorage();
    final mock = _AlamatMock([
      {
        'id': 'a1',
        'label': 'Rumah',
        'nama_penerima': 'Pembeli Satu',
        'no_hp': '081111111111',
        'alamat_lengkap': 'Jalan A 1',
        'patokan': null,
        'is_utama': true,
      },
      {
        'id': 'a2',
        'label': 'Kantor',
        'nama_penerima': 'Pembeli Dua',
        'no_hp': '082222222222',
        'alamat_lengkap': 'Jalan B 2',
        'patokan': null,
        'is_utama': false,
      },
    ]);
    await _pumpAlamat(tester, fixture, mock);
    await tester.ensureVisible(find.text('Pilih Alamat'));
    await tester.tap(find.text('Pilih Alamat'));
    await tester.pumpAndSettle();
    expect(
      mock.requests.any(
        (r) => r.method == 'PATCH' && r.path == '/alamat/a2/jadikan-utama',
      ),
      isTrue,
    );
    expect(find.text('Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ubah Alamat membuka form terisi termasuk titik tersimpan',
      (tester) async {
    _tallViewport(tester);
    final fixture = AuthFixture()..installStorage();
    final mock = _AlamatMock([
      {
        'id': 'a1',
        'label': 'Rumah',
        'nama_penerima': 'Pembeli',
        'no_hp': '081234567890',
        'alamat_lengkap':
            'Jl. Melati No. 10, Kec. Sukajadi, Kota Bandung 40162',
        'patokan': 'Gerbang samping',
        'is_utama': true,
        'latitude': -6.9,
        'longitude': 107.6,
      },
    ]);
    await _pumpAlamat(tester, fixture, mock);
    await tester.tap(find.text('Ubah Alamat'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('alamat-lengkap')))
          .controller
          ?.text,
      'Jl. Melati No. 10',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('alamat-keckota')))
          .controller
          ?.text,
      'Kec. Sukajadi, Kota Bandung',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('alamat-kodepos')))
          .controller
          ?.text,
      '40162',
    );
    expect(find.text('Lat: -6.900000, Lng: 107.600000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tautan GPS membuka pemilih peta dan menyimpan titik',
      (tester) async {
    _tallViewport(tester);
    final fixture = AuthFixture()..installStorage();
    final mock = _AlamatMock([
      {
        'id': 'a1',
        'label': 'Rumah',
        'nama_penerima': 'Pembeli',
        'no_hp': '081234567890',
        'alamat_lengkap': 'Jalan A 1',
        'patokan': null,
        'is_utama': true,
        'latitude': -6.9,
        'longitude': 107.6,
      },
    ]);
    await _pumpAlamat(tester, fixture, mock);
    await tester.ensureVisible(find.text('Atur Titik Peta GPS Sekarang ›'));
    await tester.tap(find.text('Atur Titik Peta GPS Sekarang ›'));
    await tester.pumpAndSettle();
    expect(find.text('Atur Titik Peta GPS'), findsOneWidget);
    expect(find.text('Titik peta GPS belum tersedia'), findsNothing);
    expect(find.text('Simpan Titik Ini'), findsOneWidget);
    await tester.tap(find.text('Simpan Titik Ini'));
    await tester.pumpAndSettle();
    expect(
      mock.requests.any((r) => r.method == 'PUT' && r.path == '/alamat/a1'),
      isTrue,
    );
    expect(find.text('Titik GPS tersimpan untuk Rumah.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pemilih peta tanpa titik tersimpan menolak simpan kosong',
      (tester) async {
    _tallViewport(tester);
    final fixture = AuthFixture()..installStorage();
    final mock = _AlamatMock([
      {
        'id': 'a1',
        'label': 'Rumah',
        'nama_penerima': 'Pembeli',
        'no_hp': '081234567890',
        'alamat_lengkap': 'Jalan A 1',
        'patokan': null,
        'is_utama': true,
      },
    ]);
    await _pumpAlamat(tester, fixture, mock);
    await tester.ensureVisible(find.text('Atur Titik Peta GPS Sekarang ›'));
    await tester.tap(find.text('Atur Titik Peta GPS Sekarang ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Titik Ini'));
    await tester.pumpAndSettle();
    expect(find.text('Titik belum dipilih'), findsOneWidget);
    expect(mock.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(tester.takeException(), isNull);
  });
}

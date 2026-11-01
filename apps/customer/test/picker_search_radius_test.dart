import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/features/catalog/application/jarak_toko.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pilih_toko_sheet.dart';
import 'package:gardenmart_customer/features/catalog/presentation/toko_page.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_provider.dart';
import 'package:grocery_shared/shared.dart';

const _user = Alamat(
  id: 'a1',
  label: 'Rumah',
  namaPenerima: 'Darul',
  noHp: '081234567890',
  alamatLengkap: 'Jl. Diponegoro No. 42',
  isUtama: true,
  latitude: 3.6,
  longitude: 98.68,
);

const _userTanpaGps = Alamat(
  id: 'a1',
  label: 'Rumah',
  namaPenerima: 'Darul',
  noHp: '081234567890',
  alamatLengkap: 'Jl. Diponegoro No. 42',
  isUtama: true,
);

Toko _toko({
  required String id,
  required String nama,
  required String alamat,
  required int radiusKm,
  double? latitude,
  double? longitude,
}) =>
    Toko(
      id: id,
      nama: nama,
      alamat: alamat,
      telepon: '061',
      kategori: const ['Sembako'],
      radiusKm: radiusKm,
      status: 'buka',
      metodeKirim: const ['Kurir'],
      latitude: latitude,
      longitude: longitude,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('haversine + aturan radius', () {
    test('titik sama = 0', () {
      expect(haversineKm(3.6, 98.68, 3.6, 98.68), 0.0);
    });

    test('1 derajat bujur di khatulistiwa ~111.19 km', () {
      expect(haversineKm(0, 0, 0, 1), closeTo(111.1949, 0.01));
    });

    test('1 derajat lintang di khatulistiwa ~111.19 km', () {
      expect(haversineKm(0, 0, 1, 0), closeTo(111.1949, 0.01));
    });

    test('jarakKeToko null kalau ada koordinat hilang', () {
      expect(
        jarakKeToko(
          userLat: 3.6,
          userLon: 98.68,
          tokoLat: null,
          tokoLon: 98.8,
        ),
        isNull,
      );
      expect(
        jarakKeToko(
          userLat: null,
          userLon: null,
          tokoLat: 3.7,
          tokoLon: 98.8,
        ),
        isNull,
      );
      expect(
        jarakKeToko(
          userLat: 3.6,
          userLon: 98.68,
          tokoLat: 3.5952,
          tokoLon: 98.6722,
        ),
        closeTo(1.02, 0.05),
      );
    });

    test('aturan pilih: dalam, pas batas, luar, null', () {
      expect(tokoDapatDipilih(jarakKm: 5, radiusKm: 10), isTrue);
      expect(tokoDapatDipilih(jarakKm: 10, radiusKm: 10), isTrue);
      expect(tokoDapatDipilih(jarakKm: 10.1, radiusKm: 10), isFalse);
      expect(tokoDapatDipilih(jarakKm: null, radiusKm: 10), isTrue);
      expect(tokoDapatDipilih(jarakKm: 99, radiusKm: null), isTrue);
      expect(tokoDapatDipilih(jarakKm: null, radiusKm: null), isTrue);
    });

    test('format jarak satu desimal', () {
      expect(formatJarakKm(1.04), '1.0 km');
      expect(formatJarakKm(17.36), '17.4 km');
    });
  });

  group('sheet pilih toko', () {
    Future<List<Toko>> bukaPicker(
      WidgetTester tester, {
      required List<Toko> stores,
      AsyncValue<List<Alamat>>? alamatValue,
      ValueChanged<Toko>? onPilih,
    }) async {
      final picked = <Toko>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alamatProvider.overrideWithValue(
              alamatValue ?? const AsyncValue.data([_user]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open-picker'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PilihTokoSheet(
                      stores: stores,
                      onPilih: onPilih ?? (store) => picked.add(store),
                    ),
                  ),
                  child: const Text('Buka picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-picker')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return picked;
    }

    testWidgets('cari: nama, alamat, case-insensitive, clear, tidak cocok',
        (tester) async {
      final near = _toko(
        id: 't1',
        nama: 'Indomaret Diponegoro 42',
        alamat: 'Jl. Diponegoro No. 42',
        radiusKm: 5,
        latitude: 3.5952,
        longitude: 98.6722,
      );
      final far = _toko(
        id: 't2',
        nama: 'Indomaret Setiabudi 10',
        alamat: 'Jl. Setiabudi No. 10',
        radiusKm: 10,
        latitude: 3.7,
        longitude: 98.8,
      );
      final noCoord = _toko(
        id: 't3',
        nama: 'Toko Tanpa Koordinat',
        alamat: 'Jl. Merdeka No. 1',
        radiusKm: 10,
      );
      await bukaPicker(tester, stores: [near, far, noCoord]);
      expect(find.byKey(const Key('store-search')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t1')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t2')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t3')), findsOneWidget);

      // Nama cocok (case-insensitive).
      await tester.enterText(find.byKey(const Key('store-search')), 'DIPONEGORO');
      await tester.pump();
      expect(find.byKey(const Key('store-pick-t1')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t2')), findsNothing);
      expect(find.byKey(const Key('store-pick-t3')), findsNothing);

      // Clear mengembalikan daftar penuh.
      await tester.tap(find.byKey(const Key('clear-store-search')));
      await tester.pump();
      expect(find.byKey(const Key('store-pick-t1')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t2')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t3')), findsOneWidget);

      // Alamat cocok (bukan nama).
      await tester.enterText(find.byKey(const Key('store-search')), 'merdeka');
      await tester.pump();
      expect(find.byKey(const Key('store-pick-t3')), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t1')), findsNothing);
      expect(find.byKey(const Key('store-pick-t2')), findsNothing);

      // Tidak cocok = teks jujur, bukan toko karangan.
      await tester.enterText(find.byKey(const Key('store-search')), 'zzzz');
      await tester.pump();
      expect(find.text('Tidak ada toko yang cocok'), findsOneWidget);
      expect(find.byKey(const Key('store-pick-t1')), findsNothing);
    });

    testWidgets('dalam radius: ketuk memanggil onPilih', (tester) async {
      final near = _toko(
        id: 't1',
        nama: 'Indomaret Diponegoro 42',
        alamat: 'Jl. Diponegoro No. 42',
        radiusKm: 5,
        latitude: 3.5952,
        longitude: 98.6722,
      );
      final picked = await bukaPicker(tester, stores: [near]);
      expect(find.textContaining('Maks 5 km'), findsOneWidget);
      await tester.tap(find.byKey(const Key('store-pick-t1')));
      await tester.pump();
      expect(picked.map((t) => t.id), ['t1']);
    });

    testWidgets('di luar radius: diabukan, dialog, onPilih tidak dipanggil',
        (tester) async {
      final far = _toko(
        id: 't2',
        nama: 'Indomaret Setiabudi 10',
        alamat: 'Jl. Setiabudi No. 10',
        radiusKm: 10,
        latitude: 3.7,
        longitude: 98.8,
      );
      final picked = await bukaPicker(tester, stores: [far]);
      expect(find.textContaining('Di luar jangkauan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('store-pick-t2')));
      await tester.pump();
      expect(find.text('Di luar jangkauan'), findsOneWidget);
      expect(find.textContaining('pengantaran'), findsOneWidget);
      expect(picked, isEmpty);
      // Tutup dialog: sheet masih ada, tidak pindah halaman.
      await tester.tap(find.text('Mengerti'));
      await tester.pump();
      expect(find.text('Di luar jangkauan'), findsNothing);
      expect(find.text('Pilih Toko'), findsOneWidget);
    });

    testWidgets('jarak tidak diketahui: tidak diblokir', (tester) async {
      final noCoord = _toko(
        id: 't3',
        nama: 'Toko Tanpa Koordinat',
        alamat: 'Jl. Merdeka No. 1',
        radiusKm: 10,
      );
      // (a) toko tanpa koordinat, user punya GPS.
      var picked = await bukaPicker(tester, stores: [noCoord]);
      expect(find.textContaining('Maks 10 km'), findsOneWidget);
      expect(find.textContaining('Di luar jangkauan'), findsNothing);
      await tester.tap(find.byKey(const Key('store-pick-t3')));
      await tester.pump();
      expect(picked.map((t) => t.id), ['t3']);
    });

    testWidgets('alamat utama tanpa GPS: tidak diblokir', (tester) async {
      final near = _toko(
        id: 't1',
        nama: 'Indomaret Diponegoro 42',
        alamat: 'Jl. Diponegoro No. 42',
        radiusKm: 5,
        latitude: 3.5952,
        longitude: 98.6722,
      );
      final picked = await bukaPicker(
        tester,
        stores: [near],
        alamatValue: const AsyncValue.data([_userTanpaGps]),
      );
      expect(find.textContaining('Maks 5 km'), findsOneWidget);
      expect(find.textContaining('Di luar jangkauan'), findsNothing);
      await tester.tap(find.byKey(const Key('store-pick-t1')));
      await tester.pump();
      expect(picked.map((t) => t.id), ['t1']);
    });

    testWidgets('alamat gagal dimuat: tidak diblokir', (tester) async {
      final near = _toko(
        id: 't1',
        nama: 'Indomaret Diponegoro 42',
        alamat: 'Jl. Diponegoro No. 42',
        radiusKm: 5,
        latitude: 3.5952,
        longitude: 98.6722,
      );
      final picked = await bukaPicker(
        tester,
        stores: [near],
        alamatValue: AsyncValue<List<Alamat>>.error(
          Exception('gagal'),
          StackTrace.empty,
        ),
      );
      await tester.tap(find.byKey(const Key('store-pick-t1')));
      await tester.pump();
      expect(picked.map((t) => t.id), ['t1']);
    });

    testWidgets('tidak ada toko: teks jujur, tanpa kolom cari',
        (tester) async {
      await bukaPicker(tester, stores: []);
      expect(find.text('Belum ada toko buka'), findsOneWidget);
      expect(find.byKey(const Key('store-search')), findsNothing);
    });

    testWidgets('banyak toko: sheet bisa di-scroll sampai toko terakhir',
        (tester) async {
      final stores = List.generate(
        20,
        (i) => _toko(
          id: 's$i',
          nama: 'Toko $i',
          alamat: 'Jl. No. $i',
          radiusKm: 10,
        ),
      );
      await bukaPicker(tester, stores: stores);
      // ScrollUntilVisible tidak dipakai: EditableText kolom cari juga
      // punya Scrollable internal sehingga finder Scrollable ambigu.
      // Drag langsung pada ListView membuktikan sheet bisa di-scroll.
      for (var i = 0; i < 6; i++) {
        if (find.byKey(const Key('store-pick-s19')).evaluate().isNotEmpty) {
          break;
        }
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(find.byKey(const Key('store-pick-s19')), findsOneWidget);
    });

    testWidgets('ketuk toko dalam radius membuka TokoPage', (tester) async {
      final near = _toko(
        id: 't1',
        nama: 'Indomaret Diponegoro 42',
        alamat: 'Jl. Diponegoro No. 42',
        radiusKm: 5,
        latitude: 3.5952,
        longitude: 98.6722,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alamatProvider.overrideWithValue(
              const AsyncValue.data([_user]),
            ),
            detailTokoProvider('t1').overrideWithValue(
              AsyncValue.data(
                _toko(
                  id: 't1',
                  nama: 'Indomaret Diponegoro 42',
                  alamat: 'Jl. Diponegoro No. 42',
                  radiusKm: 5,
                  latitude: 3.5952,
                  longitude: 98.6722,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open-picker'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) => PilihTokoSheet(
                      stores: [near],
                      onPilih: (store) {
                        Navigator.pop(sheetContext);
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TokoPage(store.id),
                          ),
                        );
                      },
                    ),
                  ),
                  child: const Text('Buka picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-picker')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('store-pick-t1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TokoPage), findsOneWidget);
    });
  });
}

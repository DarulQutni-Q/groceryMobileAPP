import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/checkout/presentation/checkout_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/voucher_picker_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

const _bimoli = Produk(
  id: 'p3',
  tokoId: 't1',
  nama: 'Bimoli Minyak Goreng 2L',
  harga: 33900,
  stok: 6,
  satuan: 'Pouch',
  kategori: 'Minyak Goreng',
  isTersedia: true,
);
const _ultra = Produk(
  id: 'p1',
  tokoId: 't1',
  nama: 'Ultra Milk UHT',
  harga: 17500,
  stok: 14,
  satuan: 'Pouch',
  kategori: 'Minuman',
  isTersedia: true,
);
const _indomie = Produk(
  id: 'p2',
  tokoId: 't1',
  nama: 'Indomie Spesial',
  harga: 16200,
  stok: 25,
  satuan: 'Pack',
  kategori: 'Makanan',
  isTersedia: true,
);

List<KeranjangItem> get _items => [
  const KeranjangItem(produk: _bimoli, qty: 1, dipilih: true),
  const KeranjangItem(produk: _ultra, qty: 2, dipilih: true),
  const KeranjangItem(produk: _indomie, qty: 1, dipilih: true),
];

Map<String, dynamic> _codResult() => {
  'pesanan': {
    'id': 'o1',
    'kode': 'DG-12345',
    'status': 'baru',
    'alamat_kirim': 'Jl. Diponegoro No. 42, Medan Polonia',
    'metode_kirim': 'Instant',
    'slot_waktu': 'Segera',
    'subtotal': 85100,
    'diskon': 0,
    'ongkir': 0,
    'biaya_layanan': 1000,
    'total': 86100,
    'items': [],
    'created_at': '2026-10-21T10:00:00Z',
  },
  'pembayaran': {
    'id': 'b1',
    'pesanan_id': 'o1',
    'metode': 'cod',
    'status': 'pending',
    'jumlah': 86100,
    'payment_url': null,
    'perlu_rekonsiliasi': false,
  },
};

/// Pompa halaman konfirmasi dengan backend mock yang meniru perilaku
/// backend asli: preview selalu diskon 0, ongkir 0, biaya layanan 1000.
Future<AuthFixture> bukaKonfirmasi(
  WidgetTester tester, {
  bool pakaiTombol = false,
  Map<String, Object> prefsAwal = const {},
  Future<void> Function(AuthFixture fixture)? seed,
}) async {
  final fixture = AuthFixture()..installStorage();
  // Halaman checkout kini membaca preferensi metode dari
  // SharedPreferences; tanpa mock, load() menggantung di tes.
  SharedPreferences.setMockInitialValues(prefsAwal);
  if (seed != null) await seed(fixture);
  final original = fixture.api.client.dio.httpClientAdapter as CustomerAdapter;
  fixture.api.client.dio.httpClientAdapter = CustomerAdapter((request) async {
    if (request.path == '/alamat') {
      return response([
        {
          'id': 'a1',
          'label': 'Rumah',
          'nama_penerima': 'Darul Qutni',
          'no_hp': '+62 812-8899-2122',
          'alamat_lengkap': 'Jl. Diponegoro No. 42, Medan Polonia',
          'patokan': 'Titip di meja teras depan pagar hitam',
          'is_utama': true,
        },
        {
          'id': 'a2',
          'label': 'Keluarga',
          'nama_penerima': 'Ibu Maryam (Ortu)',
          'no_hp': '+62 813-7722-9901',
          'alamat_lengkap':
              'Komplek Taman Setiabudi Indah Blok B-12, Kota Medan 20132',
          'is_utama': false,
        },
      ]);
    }
    if (request.path == '/alamat/a2/jadikan-utama') {
      return response({
        'id': 'a2',
        'label': 'Keluarga',
        'nama_penerima': 'Ibu Maryam (Ortu)',
        'no_hp': '+62 813-7722-9901',
        'alamat_lengkap':
            'Komplek Taman Setiabudi Indah Blok B-12, Kota Medan 20132',
        'is_utama': true,
      });
    }
    if (request.path == '/voucher/toko/t1') {
      return response([
        {
          'id': 'diskon30',
          'toko_id': 't1',
          'kode': 'DISKON30',
          'judul': 'Diskon 30% Produk Segar',
          'jenis': 'persen',
          'persen': 30,
          'cap': 25000,
          'min_belanja': 75000,
          'max_ongkir': 0,
          'aktif': true,
          'created_at': '2026-11-02T00:00:00Z',
        },
        {
          'id': 'gratisOngkir',
          'toko_id': 't1',
          'kode': 'GRATISONGKIR',
          'judul': 'Gratis Ongkir Instan s/d Rp 15.000',
          'jenis': 'gratis_ongkir',
          'persen': 0,
          'cap': 0,
          'min_belanja': 0,
          'max_ongkir': 15000,
          'aktif': true,
          'created_at': '2026-11-02T00:00:00Z',
        },
      ]);
    }
    if (request.path == '/checkout/preview') {
      final body = request.data as Map<String, dynamic>?;
      final pakaiDiskon30 = body?['voucher_kode'] == 'DISKON30';
      return response({
        'subtotal': 85100,
        'diskon': pakaiDiskon30 ? 25000 : 0,
        'ongkir': 0,
        'biaya_layanan': 1000,
        'total': pakaiDiskon30 ? 61100 : 86100,
      });
    }
    if (request.path == '/checkout') {
      return response(_codResult(), 201);
    }
    return original.respond(request);
  });
  fixture.saved['customer_cart_u1'] = jsonEncode({
    'version': 1,
    'items': _items.map((i) => i.toJson()).toList(),
  });
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(780, 2240);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final overrides = [
    storageProvider.overrideWithValue(fixture.storage),
    keranjangStorageProvider.overrideWithValue(fixture.storage),
    apiClientProvider.overrideWithValue(fixture.api.client),
    authProvider.overrideWith((_) => FakeAuthNotifier()),
  ];
  if (pakaiTombol) {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: customerTheme(),
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => Center(
                      child: TextButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(items: _items),
                          ),
                        ),
                        child: const Text('Ke Checkout'),
                      ),
                    ),
                  ),
                ),
                // Penjaga: halaman checkout membaca keranjangProvider
                // tanpa mendengarkan; tanpa pendengar, provider autoDispose
                // bisa terbuang sebelum selesaikanCheckout jalan.
                const _CartKeeper(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ke Checkout'));
    await tester.pumpAndSettle();
  } else {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: customerTheme(),
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: CheckoutPage(items: _items)),
                // Penjaga: lihat komentar di atas.
                const _CartKeeper(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
  return fixture;
}

/// Mendengarkan keranjang agar provider tidak ter-dispose selama tes.
class _CartKeeper extends ConsumerWidget {
  const _CartKeeper();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(keranjangProvider('u1'));
    return const SizedBox.shrink();
  }
}

Future<void> pilihCod(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('choose-payment')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('bayar-cod')),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('bayar-cod')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);

  test('voucher diskon30 caps at 25000 and respects min spend', () {
    const diskon = Voucher(
      id: 'diskon30',
      tokoId: 't1',
      kode: 'DISKON30',
      judul: 'Diskon 30%',
      jenis: 'persen',
      persen: 30,
      cap: 25000,
      minBelanja: 75000,
    );
    expect(diskon.potonganTagihan(85100), 25000);
    expect(diskon.potonganTagihan(100000), 25000);
    expect(diskon.potonganTagihan(75000), 22500);
    expect(diskon.potonganTagihan(74999), 0);
    expect(diskon.memenuhiSyarat(75000), isTrue);
    expect(diskon.memenuhiSyarat(74999), isFalse);
    const ongkir = Voucher(
      id: 'gratisOngkir',
      tokoId: 't1',
      kode: 'GRATISONGKIR',
      judul: 'Gratis Ongkir',
      jenis: 'gratis_ongkir',
      maxOngkir: 15000,
    );
    expect(ongkir.potonganTagihan(85100), 0);
    expect(ongkir.potonganOngkir(20000), 15000);
    expect(ongkir.potonganOngkir(8000), 8000);
    expect(ongkir.potonganOngkir(0), 0);
  });

  testWidgets('alamat tap opens list and picking updates card', (
    tester,
  ) async {
    await bukaKonfirmasi(tester);
    expect(find.text('Darul Qutni (+62 812-8899-2122)'), findsOneWidget);
    await tester.tap(find.text('Alamat Pengiriman'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Alamat'), findsOneWidget);
    await tester.tap(find.text('Pilih Alamat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ibu Maryam (Ortu)'), findsOneWidget);
  });

  testWidgets('delivery options open and selection updates label', (
    tester,
  ) async {
    await bukaKonfirmasi(tester);
    await tester.tap(find.text('Pengantaran Kilat Toko (15-20 Menit)'));
    await tester.pumpAndSettle();
    expect(find.text('Kurir Marketplace'), findsOneWidget);
    await tester.tap(find.text('Ambil di Toko'));
    await tester.pumpAndSettle();
    expect(find.text('Ambil di Toko'), findsOneWidget);
  });

  testWidgets('lihat semua toggles full item list', (tester) async {
    await bukaKonfirmasi(tester);
    expect(find.text('2 Pouch'), findsNothing);
    await tester.tap(find.text('Lihat Semua >'));
    await tester.pumpAndSettle();
    expect(find.text('2 Pouch'), findsOneWidget);
    await tester.tap(find.text('Sembunyikan >'));
    await tester.pumpAndSettle();
    expect(find.text('2 Pouch'), findsNothing);
  });

  testWidgets('ubah pops back to cart', (tester) async {
    await bukaKonfirmasi(tester, pakaiTombol: true);
    await tester.tap(find.byKey(const Key('summary-ubah')));
    await tester.pumpAndSettle();
    expect(find.text('Ke Checkout'), findsOneWidget);
  });

  testWidgets('note strip opens edit dialog', (tester) async {
    await bukaKonfirmasi(tester);
    await tester.tap(find.byKey(const Key('checkout-note-strip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pagar hitam no. 42.');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan: Pagar hitam no. 42.'), findsOneWidget);
  });

  testWidgets('voucher picker applies 30 percent to the bill', (
    tester,
  ) async {
    await bukaKonfirmasi(tester);
    expect(find.text('Rp 86.100'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Voucher'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voucher-diskon30')));
    await tester.pumpAndSettle();
    expect(find.text('Terpilih: Diskon 30% Produk Segar'), findsOneWidget);
    expect(find.text('-Rp 25.000'), findsOneWidget);
    expect(find.text('Rp 61.100'), findsNWidgets(2));
    expect(find.text('Hemat Rp 25.000'), findsOneWidget);
  });

  testWidgets('voucher removal restores the store bill', (tester) async {
    await bukaKonfirmasi(tester);
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voucher-diskon30')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 61.100'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voucher-tanpa')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih voucher dari toko ini'), findsOneWidget);
    expect(find.text('Rp 86.100'), findsNWidgets(2));
  });

  testWidgets('voucher free ongkir with zero shipping changes nothing', (
    tester,
  ) async {
    await bukaKonfirmasi(tester);
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voucher-gratisOngkir')));
    await tester.pumpAndSettle();
    expect(
      find.text('Terpilih: Gratis Ongkir Instan s/d Rp 15.000'),
      findsOneWidget,
    );
    expect(find.text('Rp 86.100'), findsNWidgets(2));
    expect(find.text('Hemat Rp 25.000'), findsNothing);
  });

  testWidgets('payment selection updates card', (tester) async {
    await bukaKonfirmasi(tester);
    await tester.tap(find.byKey(const Key('choose-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bayar-shopeepay')));
    await tester.pumpAndSettle();
    expect(find.text('ShopeePay'), findsOneWidget);
  });

  testWidgets('bayar with voucher proceeds for cod without warning', (
    tester,
  ) async {
    final fixture = await bukaKonfirmasi(tester);
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voucher-diskon30')));
    await tester.pumpAndSettle();
    await pilihCod(tester);
    expect(find.text('Buat Pesanan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkout-pay')));
    await tester.pumpAndSettle();
    expect(find.text('Voucher belum didukung penagihan toko'), findsNothing);
    expect(find.text('Pesanan Berhasil Dibuat'), findsOneWidget);
    final cart = jsonDecode(fixture.saved['customer_cart_u1']!) as Map;
    expect(cart['items'], isEmpty);
  });

  testWidgets('bayar cod without voucher proceeds without dialog', (
    tester,
  ) async {
    await bukaKonfirmasi(tester);
    await pilihCod(tester);
    await tester.tap(find.byKey(const Key('checkout-pay')));
    await tester.pumpAndSettle();
    expect(find.text('Voucher belum didukung penagihan toko'), findsNothing);
    expect(find.text('Pesanan Berhasil Dibuat'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_session.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';
import 'checkout_konfirmasi_test.dart' show bukaKonfirmasi;
import 'golden_test.dart' show loadTestFonts;

const _produk = Produk(
  id: 'p1',
  tokoId: 't1',
  nama: 'Ultra Milk UHT',
  harga: 17500,
  stok: 14,
  satuan: 'Pouch',
  kategori: 'Minuman',
  isTersedia: true,
);

List<KeranjangItem> get _items => [
  const KeranjangItem(produk: _produk, qty: 2, dipilih: true),
];

Map<String, dynamic> get _alamatJson => {
  'id': 'a1',
  'label': 'Rumah',
  'nama_penerima': 'Darul Qutni',
  'no_hp': '+62 812-8899-2122',
  'alamat_lengkap': 'Jl. Diponegoro No. 42, Medan Polonia',
  'patokan': 'Titip di meja teras depan pagar hitam',
  'is_utama': true,
};

/// Simpan session checkout sebelum halaman dipompa, supaya load() masuk
/// jalur tersimpan (banner tampil, dulu semua tap mati).
Future<void> seedTersimpan(AuthFixture fixture) async {
  await CheckoutSession.create(
    fixture.storage,
    'u1',
    {
      'alamat_id': 'a1',
      'metode_kirim': 'Instant',
      'metode_bayar': 'qris',
      'catatan': '',
      'items': [
        {'produk_id': 'p1', 'qty': 2},
      ],
    },
    _items,
    {
      'subtotal': 35000,
      'diskon': 0,
      'ongkir': 0,
      'biaya_layanan': 1000,
      'total': 36000,
    },
    Alamat.fromJson(_alamatJson),
  );
}

Future<void> _scrollKe(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('banner tersimpan tampil dengan tombol mulai ulang', (
    tester,
  ) async {
    await bukaKonfirmasi(tester, seed: seedTersimpan);
    expect(
      find.textContaining('Checkout sebelumnya tersimpan'),
      findsOneWidget,
    );
    expect(find.text('Mulai ulang checkout'), findsOneWidget);
  });

  testWidgets('tap alamat saat tersimpan membuka dialog, batal mempertahankan',
      (tester) async {
    await bukaKonfirmasi(tester, seed: seedTersimpan);
    await tester.tap(find.text('Alamat Pengiriman'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout tersimpan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Checkout sebelumnya tersimpan'),
      findsOneWidget,
    );
    expect(find.text('Pilih Alamat'), findsNothing);
  });

  testWidgets('tap alamat + Hapus & Ubah menghapus session dan membuka picker',
      (tester) async {
    await bukaKonfirmasi(tester, seed: seedTersimpan);
    await tester.tap(find.text('Alamat Pengiriman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus & Ubah'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Alamat'), findsOneWidget);
  });

  testWidgets('tombol mulai ulang menghapus session dan tap kembali normal',
      (tester) async {
    await bukaKonfirmasi(tester, seed: seedTersimpan);
    await tester.tap(find.text('Mulai ulang checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus & Ubah'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Checkout sebelumnya tersimpan'),
      findsNothing,
    );
    await tester.tap(find.text('Alamat Pengiriman'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Alamat'), findsOneWidget);
  });

  testWidgets('tap voucher, catatan, pengantaran, dan bayar saat tersimpan',
      (tester) async {
    await bukaKonfirmasi(tester, seed: seedTersimpan);
    await _scrollKe(tester, find.byKey(const Key('choose-voucher')));
    await tester.tap(find.byKey(const Key('choose-voucher')));
    await tester.pumpAndSettle();
    expect(find.text('Checkout tersimpan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await _scrollKe(tester, find.byKey(const Key('checkout-note-strip')));
    await tester.tap(find.byKey(const Key('checkout-note-strip')));
    await tester.pumpAndSettle();
    expect(find.text('Checkout tersimpan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengantaran Kilat Toko (15-20 Menit)'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout tersimpan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await _scrollKe(tester, find.byKey(const Key('choose-payment')));
    await tester.tap(find.byKey(const Key('choose-payment')));
    await tester.pumpAndSettle();
    expect(find.text('Checkout tersimpan'), findsOneWidget);
  });
}

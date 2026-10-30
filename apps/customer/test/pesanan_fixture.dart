import 'package:grocery_shared/shared.dart';

/// Pesanan contoh untuk golden dan widget test Pesanan Saya.
///
/// Totalnya mengikuti referensi Figma (aktif Rp 67.600, riwayat
/// Rp 89.500) supaya golden bisa dibandingkan langsung dengan referensi.
/// Data ini hanya dipakai test, bukan di kode produksi.
List<Pesanan> pesananFixture() => [
      Pesanan(
        id: 'o-diantar',
        kode: 'GM-1001',
        status: 'diantar',
        alamatKirim: 'Jl. Contoh No. 1, Bireuen',
        metodeKirim: 'Instant',
        slotWaktu: '15 menit',
        subtotal: 67600,
        diskon: 0,
        ongkir: 0,
        biayaLayanan: 0,
        total: 67600,
        items: const [
          PesananItem(
            produkId: 'p-bimoli',
            namaSnapshot: 'Bimoli 2L',
            hargaSnapshot: 33900,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-ultra',
            namaSnapshot: 'Ultra Milk 1L',
            hargaSnapshot: 17500,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-indomie',
            namaSnapshot: 'Indomie (5)',
            hargaSnapshot: 16200,
            qty: 1,
          ),
        ],
        createdAt: DateTime.utc(2026, 10, 31, 8),
      ),
      Pesanan(
        id: 'o-selesai',
        kode: 'GM-0998',
        status: 'selesai',
        alamatKirim: 'Jl. Contoh No. 2, Lhokseumawe',
        metodeKirim: 'Instant',
        slotWaktu: '15 menit',
        subtotal: 89500,
        diskon: 0,
        ongkir: 0,
        biayaLayanan: 0,
        total: 89500,
        items: const [
          PesananItem(
            produkId: 'p-beras',
            namaSnapshot: 'Beras Premium 5kg',
            hargaSnapshot: 25000,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-minyak',
            namaSnapshot: 'Minyak Goreng 2L',
            hargaSnapshot: 22000,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-gula',
            namaSnapshot: 'Gula Pasir 1kg',
            hargaSnapshot: 21500,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-telur',
            namaSnapshot: 'Telur Ayam 1kg',
            hargaSnapshot: 21000,
            qty: 1,
          ),
        ],
        createdAt: DateTime.utc(2026, 10, 2, 8),
      ),
      Pesanan(
        id: 'o-batal',
        kode: 'GM-0995',
        status: 'dibatalkan',
        alamatKirim: 'Jl. Contoh No. 3, Samalanga',
        metodeKirim: 'Instant',
        slotWaktu: '15 menit',
        subtotal: 89500,
        diskon: 0,
        ongkir: 0,
        biayaLayanan: 0,
        total: 89500,
        items: const [
          PesananItem(
            produkId: 'p-beras',
            namaSnapshot: 'Beras Premium 5kg',
            hargaSnapshot: 25000,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-minyak',
            namaSnapshot: 'Minyak Goreng 2L',
            hargaSnapshot: 22000,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-gula',
            namaSnapshot: 'Gula Pasir 1kg',
            hargaSnapshot: 21500,
            qty: 1,
          ),
          PesananItem(
            produkId: 'p-telur',
            namaSnapshot: 'Telur Ayam 1kg',
            hargaSnapshot: 21000,
            qty: 1,
          ),
        ],
        createdAt: DateTime.utc(2026, 10, 2, 8),
      ),
    ];

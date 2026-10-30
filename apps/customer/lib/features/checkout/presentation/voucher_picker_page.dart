import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../catalog/presentation/catalog_widgets.dart';

/// Jenis voucher lokal (klaim dan potongan hanya berlaku di aplikasi,
/// belum ada backend voucher/loyalty).
enum VoucherJenis { persen, gratisOngkir, tanpa }

/// Satu voucher lokal yang bisa dipilih di checkout.
///
/// [potonganTagihan] dan [potonganOngkir] adalah aturan hitung voucher
/// ini; keduanya dipakai halaman checkout untuk menampilkan rincian.
/// Nilai-nilai di [vouchersCheckout] adalah data lokal yang sama dengan
/// kartu promo (judul dan syaratnya), bukan data backend.
class VoucherLocal {
  const VoucherLocal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.jenis,
    this.persen = 0,
    this.cap = 0,
    this.minBelanja = 0,
    this.maxOngkir = 0,
  });

  /// Sentinel untuk "Tanpa voucher" (menghapus pilihan).
  static const tanpa = VoucherLocal(
    id: 'tanpa',
    title: 'Tanpa voucher',
    subtitle: '',
    jenis: VoucherJenis.tanpa,
  );

  final String id;
  final String title;
  final String subtitle;
  final VoucherJenis jenis;
  final int persen;
  final int cap;
  final int minBelanja;
  final int maxOngkir;

  /// True untuk sentinel [tanpa].
  bool get isTanpa => jenis == VoucherJenis.tanpa;
  int potonganTagihan(int subtotal) {
    if (jenis != VoucherJenis.persen) return 0;
    if (subtotal < minBelanja) return 0;
    final hitung = subtotal * persen ~/ 100;
    return hitung > cap ? cap : hitung;
  }

  /// Potongan ke ongkos kirim. Voucher gratis ongkir menanggung ongkir
  /// sampai [maxOngkir].
  int potonganOngkir(int ongkir) {
    if (jenis != VoucherJenis.gratisOngkir) return 0;
    return ongkir > maxOngkir ? maxOngkir : ongkir;
  }

  /// Apakah voucher ini bisa dipakai untuk [subtotal] sekarang.
  bool memenuhiSyarat(int subtotal) =>
      jenis != VoucherJenis.persen || subtotal >= minBelanja;
}

/// Voucher yang menghemat belanja (yang tampil di kartu checkout
/// "Ada 2 voucher aktif hemat belanja"). Voucher cashback poin tidak
/// masuk sini karena poin bukan potongan tagihan; voucher itu tetap
/// ada di halaman Promo.
const vouchersCheckout = [
  VoucherLocal(
    id: 'diskon30',
    title: 'Diskon 30% Produk Segar',
    subtitle: 'Min. belanja Rp 75rb • Maks. Rp 25rb',
    jenis: VoucherJenis.persen,
    persen: 30,
    cap: 25000,
    minBelanja: 75000,
  ),
  VoucherLocal(
    id: 'gratisOngkir',
    title: 'Gratis Ongkir Instan s/d Rp 15.000',
    subtitle: 'Khusus pengiriman toko 15 menit',
    jenis: VoucherJenis.gratisOngkir,
    maxOngkir: 15000,
  ),
];

/// Halaman pemilih voucher di checkout.
///
/// Mengetuk voucher langsung kembali dengan voucher itu (pola yang sama
/// dengan halaman pilih metode bayar). "Tanpa voucher" mengembalikan
/// [VoucherLocal.tanpa] supaya pemanggil bisa membedakan "tidak berubah"
/// (kembali biasa, null) dari "hapus pilihan".
class VoucherPickerPage extends StatelessWidget {
  const VoucherPickerPage({
    super.key,
    required this.subtotal,
    required this.ongkir,
    this.selected,
  });
  final int subtotal;
  final int ongkir;
  final VoucherLocal? selected;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    appBar: AppBar(
      backgroundColor: const Color(0xFFB5E27E),
      title: const Text('Pilih Voucher'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Voucher yang menghemat belanja',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Potongan dihitung dari keranjang saat ini.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _VoucherTile(
            key: const Key('voucher-tanpa'),
            big: '—',
            title: 'Tanpa voucher',
            subtitle: 'Tidak memakai voucher untuk pesanan ini.',
            preview: null,
            disabled: false,
            chosen: selected == null,
            onTap: () => Navigator.pop(context, VoucherLocal.tanpa),
          ),
          const SizedBox(height: 10),
          for (final voucher in vouchersCheckout) ...[
            _VoucherTile(
              key: Key('voucher-${voucher.id}'),
              big: voucher.jenis == VoucherJenis.persen
                  ? '${voucher.persen}%'
                  : 'FREE',
              title: voucher.title,
              subtitle: voucher.subtitle,
              preview: voucher.jenis == VoucherJenis.persen
                  ? (voucher.memenuhiSyarat(subtotal)
                        ? 'Hemat ${rupiah(voucher.potonganTagihan(subtotal))}'
                        : 'Min. belanja ${rupiah(voucher.minBelanja)} belum tercapai')
                  : (ongkir > 0
                        ? 'Hemat ongkir ${rupiah(voucher.potonganOngkir(ongkir))}'
                        : 'Ongkir pesanan ini sudah gratis'),
              disabled: !voucher.memenuhiSyarat(subtotal),
              chosen: selected?.id == voucher.id,
              onTap: () => Navigator.pop(context, voucher),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({
    super.key,
    required this.big,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.disabled,
    required this.chosen,
    required this.onTap,
  });
  final String big;
  final String title;
  final String subtitle;
  final String? preview;
  final bool disabled;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF2F2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: chosen ? Border.all(color: gardenInk, width: 1.5) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              big,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: disabled ? Colors.black38 : gardenInk,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: disabled ? Colors.black38 : gardenInk,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: disabled ? Colors.black38 : Colors.black54,
                    ),
                  ),
                ],
                if (preview != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? Colors.black38
                          : const Color(0xFF5E872F),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (chosen)
            const Icon(Icons.check_circle, size: 20, color: gardenInk),
        ],
      ),
    );
    if (disabled) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: tile,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../catalog/presentation/catalog_widgets.dart';
import '../application/voucher_provider.dart';

/// Halaman pemilih voucher di checkout, dari voucher aktif toko.
///
/// Mengetuk voucher langsung kembali dengan voucher itu (pola yang sama
/// dengan halaman pilih metode bayar). "Tanpa voucher" mengembalikan
/// [Voucher.tanpa] supaya pemanggil bisa membedakan "tidak berubah"
/// (kembali biasa, null) dari "hapus pilihan".
class VoucherPickerPage extends ConsumerWidget {
  const VoucherPickerPage({
    super.key,
    required this.tokoId,
    required this.subtotal,
    required this.ongkir,
    this.selected,
  });
  final String tokoId;
  final int subtotal;
  final int ongkir;
  final Voucher? selected;

  String _subtitle(Voucher voucher) {
    if (voucher.jenis == 'persen') {
      final syarat = <String>[];
      if (voucher.minBelanja > 0) {
        syarat.add('Min. belanja ${rupiah(voucher.minBelanja)}');
      }
      if (voucher.cap > 0) syarat.add('Maks. ${rupiah(voucher.cap)}');
      return syarat.join(' • ');
    }
    return 'Gratis ongkir s/d ${rupiah(voucher.maxOngkir)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voucherListProvider(tokoId));
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB5E27E),
        title: const Text('Pilih Voucher'),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gagal memuat voucher.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(voucherListProvider(tokoId)),
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
          data: (vouchers) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Voucher yang menghemat belanja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Potongan dihitung server dari keranjang saat ini.',
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
                onTap: () => Navigator.pop(context, Voucher.tanpa),
              ),
              const SizedBox(height: 10),
              if (vouchers.isEmpty)
                const Text(
                  'Toko ini belum punya voucher aktif.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              for (final voucher in vouchers) ...[
                _VoucherTile(
                  key: Key('voucher-${voucher.id}'),
                  big: voucher.jenis == 'persen'
                      ? '${voucher.persen}%'
                      : 'FREE',
                  title: voucher.judul,
                  subtitle: _subtitle(voucher),
                  preview: voucher.jenis == 'persen'
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
      ),
    );
  }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../application/promo_harga_provider.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _tanggal(DateTime value) =>
    '${value.day} ${_bulan[value.month - 1]} ${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

/// Halaman "Kilat Murah Hari Ini": promo kilat aktif dari backend, lengkap
/// dengan batas berlakunya. Promo kilat yang sudah lewat tidak tampil,
/// karena backend sudah menyaringnya.
class KilatMurahPage extends ConsumerWidget {
  const KilatMurahPage({super.key});

  void _bukaKatalog(BuildContext context, WidgetRef ref) {
    ref.read(produkProvider.notifier).filterKategori('');
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(promoHargaListProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Kilat Murah'),
          Expanded(
            child: promos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(promoHargaListProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (semua) {
                final items = semua
                    .where((p) => p.jenis == 'kilat' && p.produk != null)
                    .toList();
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: PromoBanner(
                          warna: Color(0xFFFFF3E0),
                          tag: 'KILAT MURAH',
                          judul: 'Kilat Murah',
                          subjudul: 'Harga murah berbatas waktu',
                          catatan:
                              'Total akhir mengikuti hitungan toko saat checkout.',
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: PromoEmptyState(
                          pesan: 'Belum ada promo kilat aktif.',
                          onLihatSemua: () => _bukaKatalog(context, ref),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisExtent:
                                280 +
                                (MediaQuery.textScalerOf(context).scale(100) -
                                    100),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, index) {
                            final promo = items[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ProductCard(
                                    promo.produk!,
                                    hargaPromo: promo.hargaPromo,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  promo.berakhirAt == null
                                      ? 'Berlaku selama aktif'
                                      : 'Berakhir ${_tanggal(promo.berakhirAt!.toLocal())}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC2571B),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

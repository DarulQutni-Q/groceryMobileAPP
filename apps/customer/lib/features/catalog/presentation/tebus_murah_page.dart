import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../application/promo_harga_provider.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

/// Halaman khusus tile "Tebus Murah" di beranda.
///
/// Produk yang tampil adalah produk promo tebus aktif dari backend, bukan
/// lagi tebakan kategori Camilan/Biskuit/Snack. Harga yang tampil di kartu
/// adalah harga tebus; total akhir tetap mengikuti hitungan toko saat
/// checkout, karena promo dihitung server.
class TebusMurahPage extends ConsumerWidget {
  const TebusMurahPage({super.key});

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
          const LimeHeader(title: 'Tebus Murah'),
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
                    .where((p) => p.jenis == 'tebus' && p.produk != null)
                    .toList();
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: PromoBanner(
                          warna: Color(0xFFEDE7F6),
                          tag: 'TEBUS MURAH',
                          judul: 'Tebus Murah',
                          subjudul: 'Harga tebus dari toko',
                          catatan:
                              'Total akhir mengikuti hitungan toko saat checkout.',
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: PromoEmptyState(
                          pesan: 'Belum ada promo tebus aktif.',
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
                                260 +
                                (MediaQuery.textScalerOf(context).scale(100) -
                                    100),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, index) => ProductCard(
                            items[index].produk!,
                            hargaPromo: items[index].hargaPromo,
                          ),
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

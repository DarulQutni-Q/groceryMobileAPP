import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

/// Halaman khusus tile "Promo JSM" di beranda.
///
/// Spanduk memakai kalimat promo yang sama persis dengan kartu mingguan di
/// halaman Promo & Kupon ("Promo JSM Akhir Pekan", "Diskon s/d 40%"): tidak
/// ada angka promo baru yang dikarang di sini. Produk yang tampil adalah
/// produk toko (halaman pertama katalog). Catatan di bawah spanduk jujur
/// soal harga akhir: total yang dibayar mengikuti hitungan toko saat
/// checkout, karena backend belum punya harga promo JSM.
final _promoJsmProdukProvider =
    FutureProvider.autoDispose<List<Produk>>((ref) async {
      final api = ref.watch(produkApiProvider);
      final halaman = await api.listHalaman(page: 1);
      return halaman.data;
    });

class PromoJsmPage extends ConsumerWidget {
  const PromoJsmPage({super.key});

  void _bukaKatalog(BuildContext context, WidgetRef ref) {
    ref.read(produkProvider.notifier).filterKategori('');
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produk = ref.watch(_promoJsmProdukProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Promo JSM'),
          Expanded(
            child: produk.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(_promoJsmProdukProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (items) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: PromoBanner(
                        warna: Color(0xFFE4F3D8),
                        tag: 'JSM SPECIAL',
                        judul: 'Promo JSM Akhir Pekan',
                        subjudul: 'Diskon s/d 40%',
                        catatan:
                            'Total akhir mengikuti hitungan toko saat checkout.',
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverToBoxAdapter(
                      child: PromoEmptyState(
                        pesan: 'Belum ada produk di toko ini.',
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
                        itemBuilder: (_, index) => ProductCard(items[index]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

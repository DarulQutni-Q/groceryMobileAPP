import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

/// Halaman khusus tile "Beli 1 Gratis 1" di beranda.
///
/// Produk yang tampil adalah produk toko (halaman pertama katalog), jadi
/// pengguna bisa memilih produknya dari halaman ini dan menambahkannya ke
/// keranjang. Catatan di bawah spanduk jujur soal harga akhir: total yang
/// dibayar mengikuti hitungan toko saat checkout, karena backend belum
/// punya mekanisme gratisan BOGO.
final _bogoProdukProvider = FutureProvider.autoDispose<List<Produk>>((
  ref,
) async {
  final api = ref.watch(produkApiProvider);
  final halaman = await api.listHalaman(page: 1);
  return halaman.data;
});

class BeliSatuGratisSatuPage extends ConsumerWidget {
  const BeliSatuGratisSatuPage({super.key});

  void _bukaKatalog(BuildContext context, WidgetRef ref) {
    ref.read(produkProvider.notifier).filterKategori('');
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produk = ref.watch(_bogoProdukProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Beli 1 Gratis 1'),
          Expanded(
            child: produk.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(_bogoProdukProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (items) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: PromoBanner(
                        warna: Color(0xFFFFF3D6),
                        tag: 'PROMO TOKO',
                        judul: 'Beli 1 Gratis 1',
                        subjudul: 'Beli satu produk, gratis satu produk.',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

/// Halaman khusus tile "Fresh Mart" di beranda.
///
/// Produk diambil dari kategori toko yang namanya mengandung Sayur, Buah,
/// atau Fresh (nama kategori asli dari backend lewat kategoriProvider).
/// Sama seperti Minyak & Beras: halaman sendiri, tanpa memakai filter
/// global katalog.
final _freshMartProdukProvider =
    FutureProvider.autoDispose<List<Produk>>((ref) async {
      final api = ref.watch(produkApiProvider);
      final semua = await ref.watch(kategoriProvider.future);
      final cocok = semua.where((kategori) {
        final nama = kategori.toLowerCase();
        return nama.contains('sayur') ||
            nama.contains('buah') ||
            nama.contains('fresh');
      }).toList();
      final hasil = <String, Produk>{};
      for (final kategori in cocok) {
        final halaman = await api.listHalaman(kategori: kategori, page: 1);
        for (final produk in halaman.data) {
          hasil[produk.id] = produk;
        }
      }
      return hasil.values.toList();
    });

class FreshMartPage extends ConsumerWidget {
  const FreshMartPage({super.key});

  void _bukaKatalog(BuildContext context, WidgetRef ref) {
    ref.read(produkProvider.notifier).filterKategori('');
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produk = ref.watch(_freshMartProdukProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Fresh Mart'),
          Expanded(
            child: produk.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(_freshMartProdukProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (items) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: PromoBanner(
                        warna: Color(0xFFDFF0D0),
                        tag: 'PRODUK SEGAR',
                        judul: 'Fresh Mart',
                        subjudul: 'Sayur, buah, dan produk segar harian.',
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverToBoxAdapter(
                      child: PromoEmptyState(
                        pesan: 'Belum ada produk segar di toko ini.',
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

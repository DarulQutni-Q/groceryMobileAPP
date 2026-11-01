import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart' show CatalogPage, ProductCard;
import 'catalog_widgets.dart' show PromoBanner, PromoEmptyState;

/// Halaman khusus tile "Tebus Murah" di beranda.
///
/// Spanduk memakai kalimat promo yang sama persis dengan kartu mingguan di
/// halaman Promo & Kupon ("Tebus Murah Serba 5rb", "Camilan & biskuit"):
/// tidak ada angka promo baru yang dikarang di sini. Produk yang tampil
/// adalah produk toko dari kategori Camilan, Biskuit, atau Snack. Catatan
/// di bawah spanduk jujur soal harga akhir: total yang dibayar mengikuti
/// hitungan toko saat checkout, karena backend belum punya harga tebus.
final _tebusMurahProdukProvider =
    FutureProvider.autoDispose<List<Produk>>((ref) async {
      final api = ref.watch(produkApiProvider);
      final semua = await ref.watch(kategoriProvider.future);
      final cocok = semua.where((kategori) {
        final nama = kategori.toLowerCase();
        return nama.contains('camilan') ||
            nama.contains('biskuit') ||
            nama.contains('snack');
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
    final produk = ref.watch(_tebusMurahProdukProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Tebus Murah'),
          Expanded(
            child: produk.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(_tebusMurahProdukProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (items) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: PromoBanner(
                        warna: Color(0xFFEDE7F6),
                        tag: 'SERBA 5RB',
                        judul: 'Tebus Murah Serba 5rb',
                        subjudul: 'Camilan & biskuit',
                        catatan:
                            'Total akhir mengikuti hitungan toko saat checkout.',
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverToBoxAdapter(
                      child: PromoEmptyState(
                        pesan: 'Belum ada produk tebus murah di toko ini.',
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

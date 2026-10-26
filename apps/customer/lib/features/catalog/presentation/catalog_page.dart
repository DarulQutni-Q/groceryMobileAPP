import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../application/produk_provider.dart';
import 'catalog_widgets.dart';
import 'product_page.dart';

/// Kartu produk + halaman katalog. Dipisah dari home_page.dart supaya
/// halaman lain (mis. Promo) bisa membuka katalog tanpa import cycle.
class ProductCard extends ConsumerStatefulWidget {
  const ProductCard(this.produk, {super.key});
  final Produk produk;
  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool favorite = false;
  @override
  Widget build(BuildContext context) {
    final produk = widget.produk;
    return SizedBox(
      width: 116,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('product-${produk.id}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ProductPage(produk.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 88,
                    width: double.infinity,
                    child: FotoProduk(produk),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => favorite = !favorite),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: favorite ? Colors.red.shade600 : gardenInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produk.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 ${produk.satuan}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          color: Color(0xFF78906F),
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rupiah(produk.harga),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        produk.stok == 0
                            ? 'Habis'
                            : 'Sisa ${produk.stok} ${produk.satuan}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.1,
                          color: produk.stok <= 5
                              ? Colors.red.shade700
                              : const Color(0xFF78906F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: produk.stok < 1
                        ? null
                        : () => tambahKeKeranjang(context, ref, produk),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: gardenInk,
                      minimumSize: const Size(0, 44),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '+ Keranjang',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(produkProvider);
    final categories = ref.watch(kategoriProvider);
    final products = state;
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Produk')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.metrics.extentAfter < 300) {
            ref.read(produkProvider.notifier).muatBerikutnya();
          }
          return false;
        },
        child: state.memuat
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: categories.when(
                        data: (values) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final value in ['', ...values])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    key: Key(
                                      'category-${value.isEmpty ? 'all' : value}',
                                    ),
                                    label: Text(
                                      value.isEmpty ? 'Semua' : value,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    selected: products.kategori == value,
                                    onSelected: (_) => ref
                                        .read(produkProvider.notifier)
                                        .filterKategori(value),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(kategoriProvider),
                          child: const Text(
                            'Kategori belum dapat dimuat. Coba lagi',
                          ),
                        ),
                        loading: () => const SizedBox(height: 4),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        mainAxisExtent:
                            260 +
                            (MediaQuery.textScalerOf(context).scale(100) - 100),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: state.items.length,
                      itemBuilder: (_, index) =>
                          ProductCard(state.items[index]),
                    ),
                  ),
                  if (state.items.isEmpty || state.pesan != null)
                    SliverToBoxAdapter(
                      child: Center(
                        child: TextButton(
                          onPressed: ref
                              .read(produkProvider.notifier)
                              .muatUlang,
                          child: Text(state.pesan ?? 'Produk tidak ditemukan'),
                        ),
                      ),
                    ),
                  if (state.memuatLagi)
                    const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }
}

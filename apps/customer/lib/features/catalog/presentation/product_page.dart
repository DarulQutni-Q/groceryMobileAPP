import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../application/produk_provider.dart';
import 'cart_page.dart';
import 'catalog_widgets.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage(this.id, {super.key});
  final String id;
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  int qty = 1;
  bool menyimpan = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: authBackground,
      leading: IconButton(
        key: const Key('detail-back'),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Kembali',
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text(
        'Detail Produk',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
    ),
    body: ref
        .watch(detailProdukProvider(widget.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Produk belum dapat dimuat atau sudah tidak tersedia.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(detailProdukProvider(widget.id)),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (produk) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FotoProduk(produk),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    produk.nama,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${produk.kategori} • 1 ${produk.satuan}',
                    style: const TextStyle(color: Color(0xFF728269)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    rupiah(produk.harga),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    produk.stok == 0
                        ? 'Habis'
                        : 'Sisa ${produk.stok} ${produk.satuan}',
                    style: TextStyle(
                      color: produk.stok <= 5 ? Colors.red.shade700 : gardenInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text('-'),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Jumlah',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              key: const Key('detail-minus'),
                              tooltip: 'Kurangi jumlah',
                              onPressed: qty > 1 && !menyimpan
                                  ? () => setState(() => qty--)
                                  : null,
                              icon: const Icon(Icons.remove, size: 19),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              key: const Key('detail-plus'),
                              tooltip: 'Tambah jumlah',
                              onPressed: qty < produk.stok && !menyimpan
                                  ? () => setState(() => qty++)
                                  : null,
                              icon: const Icon(Icons.add, size: 19),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('add-cart'),
                    onPressed: produk.stok < 1 || menyimpan
                        ? null
                        : () async {
                            setState(() => menyimpan = true);
                            await tambahKeKeranjang(
                              context,
                              ref,
                              produk,
                              qty: qty,
                            );
                            if (mounted) setState(() => menyimpan = false);
                          },
                    child: const Text('+ Keranjang'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const Key('buy-now'),
                    onPressed: produk.stok < 1 || menyimpan
                        ? null
                        : () async {
                            setState(() => menyimpan = true);
                            final ok = await tambahKeKeranjang(
                              context,
                              ref,
                              produk,
                              qty: qty,
                            );
                            if (!context.mounted) return;
                            setState(() => menyimpan = false);
                            if (ok) {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const CartPage(),
                                ),
                              );
                            }
                          },
                    child: const Text('Beli Sekarang'),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

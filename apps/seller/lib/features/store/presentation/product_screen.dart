import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/store_provider.dart';
import 'product_editor.dart';
import 'store_widgets.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.userId, required this.state});
  final String userId;
  final StoreState state;
  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final _search = TextEditingController();
  String _category = '';
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(storeProvider(widget.userId).notifier).search('', '');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _query() => ref
      .read(storeProvider(widget.userId).notifier)
      .search(_search.text.trim(), _category);
  Future<void> _open([Produk? product]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProductEditor(userId: widget.userId, product: product),
      ),
    );
    if (mounted) await ref.read(storeProvider(widget.userId).notifier).load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => ref.read(storeProvider(widget.userId).notifier).load(),
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _header()),
        if (widget.state.visible.isEmpty)
          SliverToBoxAdapter(child: _empty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            sliver: SliverList.builder(
              itemCount: widget.state.visible.length,
              itemBuilder: (context, index) =>
                  _product(widget.state.visible[index]),
            ),
          ),
      ],
    ),
  );

  Widget _header() {
    final state = widget.state;
    final categories = state.products.map((p) => p.kategori).toSet().toList()
      ..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          TextField(
            key: const Key('product-search'),
            controller: _search,
            onChanged: (_) {
              _timer?.cancel();
              _timer = Timer(const Duration(milliseconds: 250), _query);
            },
            decoration: InputDecoration(
              hintText: 'Cari produk',
              fillColor: const Color(0xFF83AC9E),
              prefixIcon: const Icon(Icons.search, size: 32),
              suffixIcon: IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: () {
                  _search.clear();
                  _query();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Produk',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton(
                onPressed: _open,
                child: const Text(
                  '+ Tambah Produk',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Toko ${state.toko!.nama}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in ['', ...categories])
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(category.isEmpty ? 'Semua' : category),
                        selected: _category == category,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() => _category = category);
                          _query();
                        },
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

  Widget _product(Produk product) => Card.outlined(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(product),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ProductPhoto(product: product),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${product.stok} ${product.satuan}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    rupiah(product.harga),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (product.stok <= 5)
                    StockBadge(stok: product.stok, compact: true),
                ],
              ),
            ),
            FilterChip(
              key: Key('toggle-${product.id}'),
              showCheckmark: false,
              label: Text(product.isTersedia ? 'Tersedia' : 'Habis'),
              selected: product.isTersedia,
              selectedColor: const Color(0xFF3B6341),
              backgroundColor: const Color(0xFFE85B7E),
              labelStyle: const TextStyle(color: Colors.white),
              avatar: Icon(
                product.isTersedia ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              onSelected: widget.state.busy.contains(product.id)
                  ? null
                  : (_) => ref
                        .read(storeProvider(widget.userId).notifier)
                        .mutate(product.id, () async {
                          await ref.read(produkApiProvider).toggle(product.id);
                        }),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _empty() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
    child: Column(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 110,
          color: Color(0xFF7EA895),
        ),
        const SizedBox(height: 24),
        Text(
          _search.text.isEmpty && _category.isEmpty
              ? 'Tokomu belum punya produk. Yuk, tambahkan produk pertamamu!'
              : "'${_search.text.isEmpty ? _category : _search.text}' belum ada di tokomu...",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _open, child: const Text('+ Tambah Produk')),
      ],
    ),
  );
}

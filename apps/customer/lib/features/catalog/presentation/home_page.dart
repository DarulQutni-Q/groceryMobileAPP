import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/produk_provider.dart';
import 'cart_page.dart';
import 'catalog_widgets.dart';
import 'product_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final cart = ref.watch(keranjangProvider(user.id));
    final stores = ref.watch(tokoProvider);
    final products = ref.watch(produkProvider);
    final categories = ref.watch(kategoriProvider);
    final promo = ref.watch(promoProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tokoProvider);
        ref.invalidate(kategoriProvider);
        ref.invalidate(promoProvider);
        await ref.read(produkProvider.notifier).muatUlang();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOKO TERDEKAT • 15 MNT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF69805C),
                        ),
                      ),
                      stores.when(
                        data: (value) => Text(
                          value.data.firstOrNull?.nama ?? 'Belum ada toko buka',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(tokoProvider),
                          child: const Text('Coba muat toko'),
                        ),
                        loading: () => const Text('Memuat toko...'),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => segera(context),
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_none_rounded, size: 21),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gardenInk,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  key: const Key('open-cart'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const CartPage()),
                  ),
                  tooltip: 'Keranjang',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gardenInk,
                  ),
                  icon: Badge(
                    key: Key('cart-badge-${cart.totalItem}'),
                    isLabelVisible: cart.totalItem > 0,
                    label: Text('${cart.totalItem}'),
                    backgroundColor: gardenInk,
                    child: const Icon(Icons.shopping_bag_outlined, size: 21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('catalog-search'),
              onChanged: ref.read(produkProvider.notifier).cari,
              style: const TextStyle(fontSize: 12),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari promo sembako, susu, snack...',
                prefixIcon: const Icon(Icons.search, size: 19),
                suffixIcon: IconButton(
                  onPressed: () => segera(context),
                  tooltip: 'Scan produk',
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            promo.when(
              data: (values) => values.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      margin: EdgeInsets.zero,
                      color: catalogGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              values.first.judul,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Selamat pagi, ${user.nama}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              values.first.deskripsi,
                              style: const TextStyle(fontSize: 11),
                            ),
                            TextButton(
                              onPressed: () => segera(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: gardenInk,
                                minimumSize: const Size(0, 44),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      values.first.labelTombol,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.arrow_forward, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              error: (_, _) => Card(
                color: catalogGreen,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat pagi, ${user.nama}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(promoProvider),
                        child: const Text(
                          'Promo belum dapat dimuat. Coba lagi',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
            ),
            const SizedBox(height: 10),
            const _MemberCard(),
            const SizedBox(height: 14),
            _CategoryGrid(categories: categories.asData?.value ?? const []),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kilat Murah Hari Ini',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SaleCountdown(),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CatalogPage(),
                    ),
                  ),
                  child: const Text(
                    'Lihat Semua ›',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            categories.when(
              data: (values) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final value in ['', ...values])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          key: Key('category-${value.isEmpty ? 'all' : value}'),
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
                child: const Text('Kategori belum dapat dimuat. Coba lagi'),
              ),
              loading: () => const SizedBox(height: 4),
            ),
            if (products.memuat)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      products.pesan ?? 'Produk tidak ditemukan',
                      textAlign: TextAlign.center,
                    ),
                    if (products.pesan != null)
                      TextButton(
                        onPressed: ref.read(produkProvider.notifier).muatUlang,
                        child: const Text('Coba lagi'),
                      ),
                  ],
                ),
              )
            else
              SizedBox(
                height:
                    242 + (MediaQuery.textScalerOf(context).scale(100) - 100),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 180) {
                      ref.read(produkProvider.notifier).muatBerikutnya();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount:
                        products.items.length +
                        (products.memuatLagi || products.pesan != null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        index == products.items.length
                        ? SizedBox(
                            width: 112,
                            child: Center(
                              child: products.memuatLagi
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: ref
                                          .read(produkProvider.notifier)
                                          .muatBerikutnya,
                                      child: const Text('Coba lagi'),
                                    ),
                            ),
                          )
                        : ProductCard(products.items[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard(this.produk, {super.key});
  final Produk produk;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
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
            SizedBox(
              height: 84,
              width: double.infinity,
              child: FotoProduk(produk),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 ${produk.satuan}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF78906F),
                      ),
                    ),
                    const Spacer(),
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
                child: TextButton(
                  onPressed: produk.stok < 1
                      ? null
                      : () => tambahKeKeranjang(context, ref, produk),
                  style: TextButton.styleFrom(
                    foregroundColor: gardenInk,
                    minimumSize: const Size(0, 44),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    '+ Keranjang',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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

class _MemberCard extends StatelessWidget {
  const _MemberCard();
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xFFF8FCF4),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFDAE7CE)),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poinku Member',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'POINKU AKTIF',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1,
                        color: Color(0xFF75916A),
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '0 Poin',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '+250 poin baru',
                      style: TextStyle(fontSize: 9, color: Color(0xFF5B872C)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var n = 0; n < 33; n++)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: ColoredBox(
                                    color: gardenInk,
                                    child: SizedBox(
                                      width: n % 3 == 0 ? 3 : 1,
                                      height: 36,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '9825 0180 1224',
                          style: TextStyle(fontSize: 8, letterSpacing: 1.5),
                        ),
                        const Text(
                          'Tunjukkan ke Kasir',
                          style: TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'STEMPEL BELANJA',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: .8,
                    minHeight: 6,
                    color: catalogGreen,
                    backgroundColor: Color(0xFFE3ECD8),
                  ),
                ),
              ),
              const Text(
                '8/10',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
              const Text(
                'GOLD TIER',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B753A),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.categories});
  final List<String> categories;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const entries = <(String, IconData, Color)>[
      ('Promo JSM', Icons.local_offer, Color(0xFFDD3F47)),
      ('Tebus Murah', Icons.shopping_basket, Color(0xFFCF933D)),
      ('Minyak & Beras', Icons.rice_bowl, Color(0xFF959D33)),
      ('i-Kupon', Icons.confirmation_number, Color(0xFF8B77C0)),
      ('Fresh Mart', Icons.eco, Color(0xFF76A555)),
      ('Tagihan PLN', Icons.bolt, Color(0xFFDAAF31)),
      ('Beli 1 Gratis 1', Icons.redeem, Color(0xFFC16E5E)),
      ('Lacak Kurir', Icons.local_shipping, Color(0xFF6093AF)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 4,
        runSpacing: 6,
        children: [
          for (var i = 0; i < entries.length; i++)
            SizedBox(
              width: (constraints.maxWidth - 12) / 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final candidates = i == 2
                      ? ['Beras', 'Minyak']
                      : i == 4
                      ? ['Sayur', 'Buah', 'Fresh']
                      : <String>[];
                  final category = categories
                      .where(
                        (value) => candidates.any(
                          (term) =>
                              value.toLowerCase().contains(term.toLowerCase()),
                        ),
                      )
                      .firstOrNull;
                  if (category == null) {
                    segera(context);
                  } else {
                    ref.read(produkProvider.notifier).filterKategori(category);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Badge(
                        isLabelVisible: i == 3,
                        label: const Text('4'),
                        backgroundColor: gardenInk,
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor: Colors.white,
                          child: Icon(
                            entries[i].$2,
                            size: 27,
                            color: entries[i].$3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entries[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(produkProvider);
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

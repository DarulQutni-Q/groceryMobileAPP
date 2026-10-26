import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/produk_provider.dart';
import 'cart_page.dart';
import 'catalog_widgets.dart';
import 'poinku_page.dart';
import 'product_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.now});

  /// Jam yang dipakai countdown flash sale. Null = jam asli. Diisi hanya
  /// oleh golden test supaya teks countdown tidak berubah tiap detik.
  final DateTime Function()? now;
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.home_outlined, size: 20, color: gardenInk),
                const SizedBox(width: 8),
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
                        data: (value) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                value.data.firstOrNull?.nama ??
                                    'Belum ada toko buka',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: gardenInk,
                            ),
                          ],
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
                  icon: Badge(
                    label: const Text('3'),
                    backgroundColor: dangerRed,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                    ),
                  ),
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
              controller: search,
              onChanged: ref.read(produkProvider.notifier).cari,
              style: const TextStyle(fontSize: 12),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari promo sembako, susu, snack...',
                prefixIcon: const Icon(Icons.search, size: 19),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (search.text.isNotEmpty)
                      IconButton(
                        key: const Key('clear-search'),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          search.clear();
                          ref.read(produkProvider.notifier).cari('');
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    IconButton(
                      onPressed: () => segera(context),
                      tooltip: 'Scan produk',
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                    ),
                  ],
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
                  ? _PromoBanner(
                      label: 'INDOMARET POINKU • PROMO SPESIAL',
                      greeting: 'Selamat pagi, ${user.nama}',
                      description:
                          'Ada 4 voucher belanja diskon 50% siap kamu pakai.',
                      buttonLabel: 'Klaim Semua Voucher',
                    )
                  : _PromoBanner(
                      label: values.first.judul,
                      greeting: 'Selamat pagi, ${user.nama}',
                      description: values.first.deskripsi,
                      buttonLabel: values.first.labelTombol,
                    ),
              error: (_, _) => _PromoBanner(
                label: 'INDOMARET POINKU • PROMO SPESIAL',
                greeting: 'Selamat pagi, ${user.nama}',
                description:
                    'Ada 4 voucher belanja diskon 50% siap kamu pakai.',
                buttonLabel: 'Klaim Semua Voucher',
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
            ),
            const SizedBox(height: 10),
            const _MemberCard(),
            const SizedBox(height: 12),
            _CategoryGrid(categories: categories.asData?.value ?? const []),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 18,
                        color: Color(0xFFF5B301),
                      ),
                      const Text(
                        'Kilat Murah Hari Ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SaleCountdown(
                        compact: true,
                        now: widget.now ?? DateTime.now,
                      ),
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
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
                    240 + (MediaQuery.textScalerOf(context).scale(100) - 100),
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.label,
    required this.greeting,
    required this.description,
    required this.buttonLabel,
  });
  final String label;
  final String greeting;
  final String description;
  final String buttonLabel;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: catalogGreen,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    child: Stack(
      children: [
        Positioned(
          right: -18,
          top: -24,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
        ),
        Positioned(
          right: 26,
          top: 6,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => segera(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  foregroundColor: Colors.white,
                  backgroundColor: gardenInk,
                  minimumSize: const Size(0, 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        buttonLabel,
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
      ],
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard();
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD5EEC0), Color(0xFF79C549)],
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const PoinkuPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: gardenInk,
                  child: Text(
                    'IP',
                    style: TextStyle(fontSize: 8, color: catalogGreen),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Poinku Member',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Badge(
                  label: Text(
                    '★ GOLD TIER',
                    style: TextStyle(fontSize: 7, color: Color(0xFFF7D96B)),
                  ),
                  backgroundColor: gardenInk,
                  largeSize: 16,
                  padding: EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POINKU AKTIF',
                        style: TextStyle(fontSize: 7, color: Color(0xFF526A42)),
                      ),
                      Text(
                        // Konten demo sesuai referensi Figma; backend belum
                        // punya endpoint loyalitas, jadi angka ini statis.
                        '14.850 Poin',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '+250 poin baru',
                        style: TextStyle(fontSize: 7, color: Color(0xFF466B2B)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'STEMPEL BELANJA   8/10',
                        style: TextStyle(fontSize: 7),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 2,
                        runSpacing: 3,
                        alignment: WrapAlignment.end,
                        children: [
                          for (var n = 0; n < 10; n++)
                            CircleAvatar(
                              radius: 7,
                              backgroundColor: n < 8 ? gardenInk : Colors.white,
                              child: n < 8
                                  ? const Icon(
                                      Icons.check,
                                      size: 9,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${n + 1}',
                                      style: const TextStyle(
                                        fontSize: 6,
                                        color: gardenInk,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Min. 50rb = 1 stamp • 2 lagi dapat Kupon',
                        style: TextStyle(fontSize: 6, color: Color(0xFF50693C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          for (var n = 0; n < 35; n++)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: ColoredBox(
                                  color: gardenInk,
                                  child: SizedBox(
                                    width: n % 3 == 0 ? 3 : 1,
                                    height: 23,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '9825 0180 1224',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Tunjukkan ke Kasir',
                            style: TextStyle(
                              fontSize: 7,
                              color: Color(0xFF6B7F60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      ('i-Kupon (4)', Icons.confirmation_number, Color(0xFF8B77C0)),
      ('Fresh Mart', Icons.eco, Color(0xFF76A555)),
      ('Tagihan PLN', Icons.bolt, Color(0xFFDAAF31)),
      ('Beli 1 Gratis 1', Icons.redeem, Color(0xFFC16E5E)),
      ('Lacak Kurir', Icons.local_shipping, Color(0xFF6093AF)),
    ];
    String? categoryFor(int i) {
      final candidates = i == 2
          ? ['Beras', 'Minyak']
          : i == 4
          ? ['Sayur', 'Buah', 'Fresh']
          : <String>[];
      return categories
          .where(
            (value) => candidates.any(
              (term) => value.toLowerCase().contains(term.toLowerCase()),
            ),
          )
          .firstOrNull;
    }

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < entries.length; i++)
            SizedBox(
              width: (constraints.maxWidth - 12) / 4,
              child: InkWell(
                key: Key('category-${categoryFor(i) ?? 'soon-$i'}'),
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
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: Colors.white,
                        child: Icon(
                          entries[i].$2,
                          size: 27,
                          color: entries[i].$3,
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

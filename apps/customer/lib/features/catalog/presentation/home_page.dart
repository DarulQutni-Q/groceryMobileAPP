import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../checkout/application/checkout_provider.dart';
import '../application/produk_provider.dart';
import 'cart_page.dart';
import 'catalog_page.dart';
import 'chat_driver_page.dart';
import 'notifications_page.dart';
import 'pesanan_page.dart';
import 'promo_page.dart';
import 'scan_qr_page.dart';
import '../../checkout/presentation/struk_page.dart';
import 'catalog_widgets.dart';
import 'poinku_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.now, this.onGoToTab});

  /// Jam yang dipakai countdown flash sale. Null = jam asli. Diisi hanya
  /// oleh golden test supaya teks countdown tidak berubah tiap detik.
  final DateTime Function()? now;

  /// Pindah tab shell (1 = Promo, 3 = Pesanan). Null kalau Home
  /// dipakai mandiri (golden test): tombol pakai fallback dorong halaman.
  final ValueChanged<int>? onGoToTab;
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
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ),
                  tooltip: 'Notifikasi',
                  icon: Badge(
                    isLabelVisible: ref
                        .watch(pendingCheckoutProvider)
                        .maybeWhen(data: (value) => value, orElse: () => false),
                    label: const Text('1'),
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
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari promo sembako, susu, snack...',
                hintStyle: const TextStyle(fontSize: 13),
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
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanQrPage()),
                      ),
                      tooltip: 'Scan produk',
                      icon: const Icon(Icons.qr_code_scanner, size: 19),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFD5EEC0),
                        foregroundColor: gardenInk,
                        shape: const CircleBorder(),
                        fixedSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
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
                      onClaim: () => _goToPromoTab(context, widget.onGoToTab),
                    )
                  : _PromoBanner(
                      label: values.first.judul,
                      greeting: 'Selamat pagi, ${user.nama}',
                      description: values.first.deskripsi,
                      buttonLabel: values.first.labelTombol,
                      onClaim: () => _goToPromoTab(context, widget.onGoToTab),
                    ),
              error: (_, _) => _PromoBanner(
                label: 'INDOMARET POINKU • PROMO SPESIAL',
                greeting: 'Selamat pagi, ${user.nama}',
                description:
                    'Ada 4 voucher belanja diskon 50% siap kamu pakai.',
                buttonLabel: 'Klaim Semua Voucher',
                onClaim: () => _goToPromoTab(context, widget.onGoToTab),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
            ),
            const SizedBox(height: 10),
            const _MemberCard(),
            const SizedBox(height: 12),
            _CategoryGrid(
              categories: categories.asData?.value ?? const [],
              onGoToTab: widget.onGoToTab,
            ),
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
                        : ProductCard(products.items[index], home: true),
                  ),
                ),
              ),
          ],
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
    required this.onClaim,
  });
  final String label;
  final String greeting;
  final String description;
  final String buttonLabel;
  final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: catalogGreen,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Stack(
      children: [
        Positioned(
          left: -34,
          bottom: -46,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onClaim,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: Colors.white,
                  backgroundColor: gardenInk,
                  minimumSize: const Size(0, 44),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 15),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                    radius: 11,
                    backgroundColor: gardenInk,
                    child: Text(
                      'IP',
                      style: TextStyle(fontSize: 9, color: catalogGreen),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Poinku Member',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Badge(
                    label: Text(
                      '★ GOLD TIER',
                      style: TextStyle(fontSize: 8, color: Color(0xFFF7D96B)),
                    ),
                    backgroundColor: gardenInk,
                    largeSize: 16,
                    padding: EdgeInsets.symmetric(horizontal: 8),
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
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xFF526A42),
                          ),
                        ),
                        Text(
                          // Konten demo sesuai referensi Figma; backend belum
                          // punya endpoint loyalitas, jadi angka ini statis.
                          '14.850 Poin',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+250 poin baru',
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xFF466B2B),
                          ),
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
                          style: TextStyle(fontSize: 8),
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
                                backgroundColor: n < 8
                                    ? gardenInk
                                    : Colors.white,
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
                          style: TextStyle(
                            fontSize: 7,
                            color: Color(0xFF50693C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
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
                                      height: 26,
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

/// Pindah ke tab Promo (index 1). Di luar shell (mis. golden test),
/// dorong halaman Promo mandiri dengan tombol kembali.
void _goToPromoTab(BuildContext context, ValueChanged<int>? onGoToTab) {
  final go = onGoToTab;
  if (go != null) {
    go(1);
    return;
  }
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => const Scaffold(body: PromoPage(showBack: true)),
    ),
  );
}

/// Pindah ke tab Pesanan (index 3). Di luar shell, dorong halaman
/// Pesanan mandiri dengan tombol kembali.
void _goToPesananTab(BuildContext context, ValueChanged<int>? onGoToTab) {
  final go = onGoToTab;
  if (go != null) {
    go(3);
    return;
  }
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        body: PesananPage(
          showBack: true,
          onLihatStruk: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const StrukPage()),
          ),
          onChatDriver: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const ChatDriverPage()),
          ),
          onBeliLagi: () => Navigator.maybePop(context),
        ),
      ),
    ),
  );
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.categories, this.onGoToTab});
  final List<String> categories;
  final ValueChanged<int>? onGoToTab;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ikon outline gelap tunggal sesuai referensi (bukan warna-warni).
    const entries = <(String, IconData)>[
      ('Promo JSM', Icons.calendar_today_outlined),
      ('Tebus Murah', Icons.discount_outlined),
      ('Minyak & Beras', Icons.rice_bowl),
      ('i-Kupon (4)', Icons.confirmation_number_outlined),
      ('Fresh Mart', Icons.schedule_outlined),
      ('Tagihan PLN', Icons.bolt),
      ('Beli 1 Gratis 1', Icons.shopping_cart_outlined),
      ('Lacak Kurir', Icons.local_shipping_outlined),
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
        runSpacing: 16,
        children: [
          for (var i = 0; i < entries.length; i++)
            SizedBox(
              width: (constraints.maxWidth - 12) / 4,
              child: InkWell(
                key: Key('category-${categoryFor(i) ?? 'soon-$i'}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  switch (i) {
                    case 0:
                    case 1:
                    case 3:
                    case 6:
                      _goToPromoTab(context, onGoToTab);
                    case 2:
                    case 4:
                      final category = categoryFor(i);
                      if (category != null) {
                        ref
                            .read(produkProvider.notifier)
                            .filterKategori(category);
                      }
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const CatalogPage()),
                      );
                    case 5:
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Tagihan PLN'),
                          content: const Text(
                            'Pembayaran tagihan belum tersedia di GardenMart '
                            'karena belum ada layanan tagihan di backend.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    case 7:
                      _goToPesananTab(context, onGoToTab);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Kotak membulat hijau muda sesuai referensi, bukan
                      // lingkaran putih: di referensi tile-nya kotak
                      // membulat, jadi lingkaran lama yang bikin beranda
                      // kelihatan beda.
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFDDF0C6), Color(0xFFBEE59C)],
                          ),
                        ),
                        child: i == 1
                            // Lencana % melingkar sesuai referensi (bukan
                            // ikon tag): lingkaran outline dengan % di tengah.
                            ? Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: gardenInk,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: gardenInk,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(entries[i].$2, size: 26, color: gardenInk),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entries[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
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

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

import '../../../core/theme.dart';

const catalogGreen = Color(0xFF96E23B);
const cartBackground = Color(0xFFE8F1E2);
const totalGreen = Color(0xFF9FDD56);

/// Spanduk promo untuk halaman promo khusus (JSM, Tebus Murah, Minyak &
/// Beras, Fresh Mart, Beli 1 Gratis 1): judul + subjudul + catatan jujur
/// opsional. Bukan klaim diskon per produk: harga produk tetap harga toko.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.warna,
    required this.tag,
    required this.judul,
    required this.subjudul,
    this.catatan,
  });
  final Color warna;
  final String tag, judul, subjudul;
  final String? catatan;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: textGrey,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          judul,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: gardenInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(subjudul, style: const TextStyle(fontSize: 12, color: textGrey)),
        if (catatan != null) ...[
          const SizedBox(height: 8),
          Text(catatan!, style: const TextStyle(fontSize: 11, color: textGrey)),
        ],
      ],
    ),
  );
}

/// Keadaan kosong halaman promo: ikon + pesan + tombol ke katalog.
class PromoEmptyState extends StatelessWidget {
  const PromoEmptyState({
    super.key,
    required this.pesan,
    this.onLihatSemua,
  });
  final String pesan;
  final VoidCallback? onLihatSemua;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const Icon(
          Icons.shopping_basket_outlined,
          size: 40,
          color: textGrey,
        ),
        const SizedBox(height: 12),
        Text(
          pesan,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: textGrey),
        ),
        if (onLihatSemua != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLihatSemua,
            child: const Text('Lihat semua produk'),
          ),
        ],
      ],
    ),
  );
}

String rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

void pesanCart(BuildContext context, Keranjang value) {
  if (value.pesan != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(value.pesan!)));
  }
}

class FotoProduk extends ConsumerWidget {
  const FotoProduk(this.produk, {super.key, this.fit = BoxFit.contain});
  final Produk produk;
  final BoxFit fit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback({bool error = false}) => ColoredBox(
      color: error ? const Color(0xFFF0F5EB) : catalogGreen,
      child: Center(
        child: Icon(
          error ? Icons.broken_image_outlined : Icons.shopping_bag_outlined,
          size: 36,
          color: error ? const Color(0xFF75946A) : Colors.white,
        ),
      ),
    );
    final url = produk.fotoUrl;
    if (url == null || url.isEmpty) return fallback();
    return CachedNetworkImage(
      imageUrl: Uri.parse(ref.watch(apiClientProvider).dio.options.baseUrl)
          .resolve(url)
          .toString(),
      fit: fit,
      placeholder: (_, _) => fallback(),
      errorWidget: (_, _, _) => fallback(error: true),
    );
  }
}

class SaleCountdown extends StatefulWidget {
  const SaleCountdown({
    super.key,
    this.now = DateTime.now,
    this.compact = false,
  });
  final bool compact;
  final DateTime Function() now;
  @override
  State<SaleCountdown> createState() => _SaleCountdownState();
}

class _SaleCountdownState extends State<SaleCountdown> {
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59);
    final seconds = end.difference(now).inSeconds.clamp(0, 86400);
    String two(int n) => n.toString().padLeft(2, '0');
    final text = Text(
      'BERAKHIR: ${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}',
      style: TextStyle(
        fontSize: widget.compact ? 8 : 10,
        fontWeight: FontWeight.w600,
        color: widget.compact ? Colors.white : const Color(0xFF7A3C2E),
      ),
    );
    return widget.compact
        ? Chip(
            label: text,
            backgroundColor: const Color(0xFFB22E32),
            side: BorderSide.none,
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        : text;
  }
}

Future<bool> tambahKeKeranjang(
  BuildContext context,
  WidgetRef ref,
  Produk produk, {
  int qty = 1,
}) async {
  final userId = ref.read(authProvider).user!.id;
  final provider = keranjangProvider(userId);
  final notifier = ref.read(provider.notifier);
  await notifier.siap;
  if (!context.mounted) return false;
  final cart = ref.read(provider);
  var ganti = false;
  if (cart.tokoId != null && cart.tokoId != produk.tokoId) {
    ganti =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ganti toko?'),
            content: const Text(
              'Keranjang berisi produk dari toko lain. Ganti isinya dengan produk dari toko ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ganti toko'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ganti || !context.mounted) return false;
  }
  final ok = await notifier.tambahItem(produk, qty: qty, gantiToko: ganti);
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Ditambahkan ke keranjang'
            : ref.read(provider).pesan ?? 'Keranjang belum dapat diperbarui',
      ),
    ),
  );
  return ok;
}

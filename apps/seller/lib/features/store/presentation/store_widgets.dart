import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/seller_theme.dart';
import '../../../shared/auth_layout.dart';
import '../../auth/application/auth_provider.dart';
String rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

class StoreBackground extends StatelessWidget {
  const StoreBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Stack(
      children: [
        Positioned(
          top: -size.maxHeight * .44,
          left: size.maxWidth * .15,
          width: size.maxWidth * 2,
          height: size.maxHeight * .86,
          child: Transform.rotate(
            angle: .55,
            child: const ClipOval(child: ColoredBox(color: Color(0xFFE3E6D1))),
          ),
        ),
        Positioned(
          bottom: -size.maxHeight * .45,
          left: -size.maxWidth,
          width: size.maxWidth * 2.4,
          height: size.maxHeight,
          child: Transform.rotate(
            angle: .35,
            child: const ClipOval(child: ColoredBox(color: Color(0xFFF3F6E3))),
          ),
        ),
        child,
      ],
    ),
  );
}

class StorePage extends StatelessWidget {
  const StorePage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(bodyColor: Colors.black, displayColor: Colors.black),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    child: Scaffold(
      body: StoreBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 18, 8),
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProductPhoto extends ConsumerWidget {
  const ProductPhoto({super.key, required this.product, this.size = 72});
  final Produk product;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = product.fotoUrl;
    final image = url == null
        ? null
        : Uri.parse(ref.watch(apiBaseUrlProvider)).resolve(url).toString();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: image == null
          ? const Icon(Icons.inventory_2_outlined, size: 34)
          : Image.network(
              image,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) =>
                  const Icon(Icons.broken_image_outlined),
            ),
    );
  }
}

class TokoLogo extends ConsumerWidget {
  const TokoLogo({super.key, required this.toko, this.size = 76});
  final Toko toko;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = SizedBox(
      width: size,
      height: size,
      child: ReferenceArtwork(
        asset: 'splash.png',
        rect: const Rect.fromLTWH(81, 221, 307, 308),
        width: size,
        semanticLabel: 'Logo toko',
      ),
    );
    final logo = toko.logoUrl;
    if (logo == null || logo.isEmpty) {
      return placeholder;
    }
    final url =
        Uri.parse(ref.watch(apiBaseUrlProvider)).resolve(logo).toString();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stack) => placeholder,
        ),
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stok, this.compact = false});
  final int stok;
  final bool compact;
  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    labelPadding: EdgeInsets.symmetric(horizontal: compact ? 3 : 4),
    backgroundColor: stok == 0
        ? const Color(0xFFE85B7E)
        : const Color(0xFFE7B928),
    side: BorderSide.none,
    avatar: Icon(
      stok == 0 ? Icons.close : Icons.warning_amber,
      size: compact ? 12 : 18,
      color: Colors.white,
    ),
    label: Text(
      stok == 0 ? 'Habis' : 'Sisa $stok',
      style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 14),
    ),
  );
}

void storeMessage(BuildContext context, String message, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB3261E) : sellerInk,
      ),
    );

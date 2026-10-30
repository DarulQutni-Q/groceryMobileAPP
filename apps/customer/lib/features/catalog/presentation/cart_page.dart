import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../checkout/presentation/alamat_page.dart';
import '../../checkout/presentation/checkout_page.dart';
import 'promo_page.dart';
import '../application/produk_provider.dart';
import '../application/placeholder_diskon.dart';
import 'catalog_widgets.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final provider = keranjangProvider(user.id);
    final cart = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    ref.listen(provider, (before, next) {
      if (next.pesan != null && next.pesan != before?.pesan) {
        pesanCart(context, next);
      }
    });
    final storeId = cart.tokoId;
    final store = storeId == null
        ? null
        : ref.watch(detailTokoProvider(storeId));
    return Scaffold(
      backgroundColor: cartBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  RoundIconButton(
                    key: const Key('cart-back'),
                    icon: Icons.arrow_back,
                    background: limePale,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Keranjang Belanja',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: limePale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: gardenInk,
                      ),
                    ),
                  ),
                  const Spacer(),
                  RoundIconButton(
                    icon: Icons.more_vert,
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (sheetContext) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: dangerRed,
                              ),
                              title: const Text('Kosongkan Keranjang'),
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                await ref.read(provider.notifier).kosongkan();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Keranjang dikosongkan'),
                                    ),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.close),
                              title: const Text('Tutup'),
                              onTap: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cart.memuat
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      children: [
                        if (store != null)
                          store.when(
                            data: (value) => Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 17,
                                      backgroundColor: Color(0xFFE9F4DD),
                                      child: Icon(
                                        Icons.house_outlined,
                                        size: 20,
                                        color: gardenInk,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dikirim dari ${value.nama}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Estimasi Tiba 15-20 Mnt • ${value.jamTutup == null ? 'Jam toko belum diatur' : 'Buka s/d ${value.jamTutup!.substring(0, 5)}'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF73876B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.push<void>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AlamatPage(),
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        minimumSize: const Size(44, 44),
                                      ),
                                      child: const Text(
                                        'Ubah >',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5E872F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            error: (_, _) => TextButton(
                              onPressed: () =>
                                  ref.invalidate(detailTokoProvider(storeId!)),
                              child: const Text(
                                'Info toko belum tersedia. Coba lagi',
                              ),
                            ),
                            loading: () =>
                                const LinearProgressIndicator(minHeight: 2),
                          ),
                        if (cart.pesan != null)
                          MaterialBanner(
                            content: Text(cart.pesan!),
                            backgroundColor: const Color(0xFFFFF3E0),
                            actions: [
                              TextButton(
                                onPressed: notifier.muatUlang,
                                child: const Text('Coba lagi'),
                              ),
                              TextButton(
                                onPressed: notifier.kosongkan,
                                child: const Text('Kosongkan'),
                              ),
                            ],
                          ),
                        if (cart.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 70),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 66,
                                  color: Color(0xFF8CA879),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Keranjang masih kosong',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Yuk, pilih kebutuhan belanjamu.'),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Mulai Belanja'),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              _SquareCheck(
                                key: const Key('select-all'),
                                value: cart.semuaDipilih,
                                onChanged: (value) =>
                                    notifier.pilihSemua(value),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pilih Semua (${cart.items.length} Produk)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                key: const Key('delete-selected'),
                                onPressed: cart.jumlahDipilih == 0
                                    ? null
                                    : notifier.hapusDipilih,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: cart.jumlahDipilih == 0
                                      ? Colors.grey
                                      : const Color(0xFFD65B52),
                                ),
                                label: Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: cart.jumlahDipilih == 0
                                        ? Colors.grey
                                        : const Color(0xFFD65B52),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                for (final item in cart.items)
                                  Padding(
                                    key: ValueKey(item.produk.id),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _CartRow(item, notifier),
                                  ),
                              ],
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.only(top: 4),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Scaffold(
                                    body: PromoPage(showBack: true),
                                  ),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number_outlined,
                                      color: Color(0xFF7A9B52),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gunakan / Masukkan Voucher',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Ada 2 voucher aktif hemat belanja',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF73876B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Hemat s/d Rp 25rb >',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5E872F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            _PaymentBar(cart),
            if (totalHematPlaceholder(cart.items) > 0)
              _SavingsBanner(totalHematPlaceholder(cart.items)),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow(this.item, this.notifier);
  final KeranjangItem item;
  final KeranjangNotifier notifier;
  @override
  Widget build(BuildContext context) {
    final p = item.produk;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SquareCheck(
              key: Key('cart-check-${p.id}'),
              value: item.dipilih,
              onChanged: (value) => notifier.pilihItem(p.id, value),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 68, height: 80, child: FotoProduk(p)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.kategori} • ${p.satuan}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7F9275),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sisa ${p.stok} pcs',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.stok <= 5
                          ? Colors.red.shade700
                          : const Color(0xFF6B875A),
                    ),
                  ),
                  const SizedBox(height: 7),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final diskon = placeholderDiskonUntuk(p);
                      final persen = diskon?.persenDiskon(p.harga) ?? 0;
                      final price = Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            rupiah(p.harga),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (diskon != null && persen > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: dangerRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-$persen%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              rupiah(diskon.hargaAsli),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A9A82),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      );
                      final stepper = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepperButton(
                            key: Key('cart-minus-${p.id}'),
                            icon: Icons.remove,
                            onPressed: () => notifier.kurangItem(p.id),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.qty}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StepperButton(
                            key: Key('cart-plus-${p.id}'),
                            icon: Icons.add,
                            filled: true,
                            onPressed: item.qty < p.stok
                                ? () => notifier.tambahQty(p.id)
                                : null,
                          ),
                        ],
                      );
                      if (constraints.maxWidth >= 210 &&
                          MediaQuery.textScalerOf(context).scale(10) <= 12) {
                        return Row(
                          children: [
                            Expanded(child: price),
                            const SizedBox(width: 6),
                            stepper,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          price,
                          Align(
                            alignment: Alignment.centerRight,
                            child: stepper,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner hemat di bawah tombol checkout: kartu putih membulat dengan
/// ikon sparkle, nilainya dihitung dari diskon placeholder (bukan literal).
class _SavingsBanner extends StatelessWidget {
  const _SavingsBanner(this.totalHemat);
  final int totalHemat;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    child: Container(
      key: const Key('cart-savings-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF5E872F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total kamu hemat ${rupiah(totalHemat)} di pesanan ini!',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: gardenInk,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar(this.cart);
  final Keranjang cart;
  @override
  Widget build(BuildContext context) => Material(
    color: totalGreen,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                rupiah(cart.subtotal),
                key: Key('cart-total-${cart.subtotal}'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Rincian Biaya',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (final row in [
                            ('Subtotal', rupiah(cart.subtotal)),
                            (
                              'Diskon',
                              rupiah(totalHematPlaceholder(cart.items)),
                            ),
                            ('Ongkir', rupiah(0)),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Text(row.$1), Text(row.$2)],
                              ),
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                rupiah(cart.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                ),
                child: const Text(
                  'Rincian Biaya ^',
                  style: TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          );
          // DarkPillButton, bukan FilledButton polos: FilledButton yang
          // hanya mengandalkan tema merender teksnya abu-abu gelap
          // (#657168) di atas tombol gelap di golden test, entah kenapa
          // foregroundColor tema tidak kepakai di sini. Pola DarkPillButton
          // (style eksplisit level widget) terbukti merender teks putih.
          final checkout = DarkPillButton(
            label: 'Checkout (${cart.jumlahDipilih} Barang) >',
            height: 52,
            fontSize: 13,
            onPressed: cart.jumlahDipilih == 0
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(
                        items: cart.items.where((i) => i.dipilih).toList(),
                      ),
                    ),
                  ),
          );
          if (constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(10) > 12) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, checkout],
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: info),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: checkout),
            ],
          );
        },
      ),
    ),
  );
}

/// Kotak centang persegi sesuai Figma (bukan Checkbox Material).
class _SquareCheck extends StatelessWidget {
  const _SquareCheck({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    customBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? gardenInk : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: value
            ? null
            : Border.all(color: const Color(0xFF9DB08F), width: 1.5),
      ),
      child: value
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    ),
  );
}

/// Tombol stepper lingkaran: kurang outline putih, tambah hijau gelap penuh.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? (enabled ? gardenInk : Colors.grey.shade300)
              : Colors.white,
          border: filled
              ? null
              : Border.all(
                  color: enabled ? gardenBorder : Colors.grey.shade300,
                  width: 1.5,
                ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? Colors.white
              : (enabled ? gardenInk : Colors.grey.shade400),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/produk_provider.dart';
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
      appBar: AppBar(
        backgroundColor: cartBackground,
        leading: IconButton(
          key: const Key('cart-back'),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Keranjang Belanja',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => segera(context),
            tooltip: 'Menu keranjang',
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 17,
                                      backgroundColor: Color(0xFFE9F4DD),
                                      child: Icon(
                                        Icons.storefront_outlined,
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
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '⚡ Estimasi Tiba 15–20 Mnt • ${value.jamTutup == null ? 'Jam toko belum diatur' : 'Buka s/d ${value.jamTutup!.substring(0, 5)}'}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF73876B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => segera(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        minimumSize: const Size(44, 44),
                                      ),
                                      child: const Text(
                                        'Ubah ›',
                                        style: TextStyle(fontSize: 11),
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
                              Checkbox(
                                key: const Key('select-all'),
                                value: cart.semuaDipilih,
                                onChanged: (value) =>
                                    notifier.pilihSemua(value ?? false),
                                activeColor: gardenInk,
                              ),
                              Expanded(
                                child: Text(
                                  'Pilih Semua (${cart.items.length} Produk)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('delete-selected'),
                                onPressed: cart.jumlahDipilih == 0
                                    ? null
                                    : notifier.hapusDipilih,
                                child: Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: cart.jumlahDipilih == 0
                                        ? Colors.grey
                                        : const Color(0xFFD65B52),
                                    fontSize: 12,
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
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: InkWell(
                              onTap: () => segera(context),
                              borderRadius: BorderRadius.circular(18),
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
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Ada 2 voucher aktif hemat belanja',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF73876B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Hemat s/d\nRp 25rb ›',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: item.dipilih,
                onChanged: (value) => notifier.pilihItem(p.id, value ?? false),
                activeColor: gardenInk,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 68, height: 94, child: FotoProduk(p)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.kategori} • 1 ${p.satuan}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF7F9275),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sisa ${p.stok} ${p.satuan}',
                    style: TextStyle(
                      fontSize: 10,
                      color: p.stok <= 5
                          ? Colors.red.shade700
                          : const Color(0xFF6B875A),
                    ),
                  ),
                  const SizedBox(height: 7),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final price = Text(
                        rupiah(p.harga),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                      final stepper = DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8EF),
                          border: Border.all(color: gardenBorder),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('cart-minus-${p.id}'),
                              onPressed: () => notifier.kurangItem(p.id),
                              tooltip: 'Kurangi ${p.nama}',
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 21,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                            Text(
                              '${item.qty}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              key: Key('cart-plus-${p.id}'),
                              onPressed: item.qty < p.stok
                                  ? () => notifier.tambahQty(p.id)
                                  : null,
                              tooltip: 'Tambah ${p.nama}',
                              icon: const Icon(Icons.add_circle, size: 21),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                      );
                      if (constraints.maxWidth >= 210 &&
                          MediaQuery.textScalerOf(context).scale(10) <= 12) {
                        return Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: price,
                              ),
                            ),
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
                  fontSize: 23,
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
                            ('Diskon', rupiah(0)),
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
                  'Rincian Biaya ⌃',
                  style: TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          );
          final checkout = FilledButton(
            onPressed: cart.jumlahDipilih == 0 ? null : () => segera(context),
            child: Text(
              'Checkout (${cart.jumlahDipilih} Barang)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
              Expanded(child: info),
              const SizedBox(width: 16),
              Expanded(child: checkout),
            ],
          );
        },
      ),
    ),
  );
}

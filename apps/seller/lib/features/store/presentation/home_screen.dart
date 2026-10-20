import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../pesanan/application/pesanan_provider.dart';
import '../../pesanan/presentation/pesanan_widgets.dart';
import '../application/store_provider.dart';
import 'product_editor.dart';
import 'store_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.state,
    required this.openOrders,
  });
  final User user;
  final StoreState state;
  final VoidCallback openOrders;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toko = state.toko!;
    final orders = ref.watch(pesananProvider(user.id));
    ref.listen(pesananProvider(user.id), (previous, next) {
      if (next.error != null &&
          next.error != previous?.error &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        storeMessage(
          context,
          'Statistik belum dimuat: ${next.error!}',
          error: true,
        );
      }
    });
    final low = state.products.where((p) => p.stok <= 5).toList();
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(storeProvider(user.id).notifier).load(),
          ref.read(pesananProvider(user.id).notifier).load(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toko ${toko.nama}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Selamat Pagi, ${user.nama}',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
              ActionChip(
                key: const Key('toko-status'),
                label: Text(toko.status == 'buka' ? 'Buka' : 'Tutup'),
                backgroundColor: toko.status == 'buka'
                    ? const Color(0xFF192D1E)
                    : const Color(0xFFECE5D0),
                labelStyle: TextStyle(
                  color: toko.status == 'buka' ? Colors.white : Colors.black,
                ),
                onPressed: state.busy.contains('status')
                    ? null
                    : () => ref.read(storeProvider(user.id).notifier).mutate(
                        'status',
                        () async {
                          await ref
                              .read(tokoApiProvider)
                              .updateStatus(
                                toko.status == 'buka' ? 'tutup' : 'buka',
                              );
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _notice(context, ref, toko),
          const SizedBox(height: 8),
          if (orders.loading) const LinearProgressIndicator(),
          if (orders.error != null)
            PesananError(
              message: 'Statistik belum dapat dimuat.',
              retry: () => ref.read(pesananProvider(user.id).notifier).load(),
            ),
          _statistics(low.length, orders),
          const SizedBox(height: 12),
          const Text(
            'Perlu Tindakan',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (low.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text('Tidak ada stok yang perlu diisi.'),
            ),
          for (final product in low) _critical(context, product),
        ],
      ),
    );
  }

  Widget _notice(BuildContext context, WidgetRef ref, Toko toko) {
    final closed = toko.status == 'tutup';
    return Card.filled(
      color: closed ? const Color(0xFFECE5D0) : const Color(0xFF84A18A),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              closed ? Icons.storefront_outlined : Icons.notifications_none,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                closed
                    ? 'Toko sedang tutup, pembeli belum bisa memesan'
                    : '3 Pesan baru menunggu',
                style: TextStyle(
                  fontSize: 16,
                  color: closed ? Colors.black : Colors.white,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: state.busy.contains('status')
                  ? null
                  : closed
                  ? () => ref.read(storeProvider(user.id).notifier).mutate(
                      'status',
                      () async {
                        await ref.read(tokoApiProvider).updateStatus('buka');
                      },
                    )
                  : openOrders,
              child: Text(closed ? 'Buka Toko' : 'Lihat'),
            ),
          ],
        ),
      ),
    );
  }

  List<Pesanan> _completedToday(List<Pesanan> orders) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return orders.where((order) {
      final day = order.updatedAt?.toUtc().add(const Duration(hours: 7));
      return order.status == 'selesai' &&
          day != null &&
          day.year == now.year &&
          day.month == now.month &&
          day.day == now.day;
    }).toList();
  }

  Widget _statistics(int low, PesananState orders) {
    final completed = _completedToday(orders.orders);
    final total = completed.fold(0, (sum, order) => sum + order.total);
    final qty = completed.fold(
      0,
      (sum, order) => sum + order.items.fold(0, (qty, item) => qty + item.qty),
    );
    final pending = orders.loading
        ? '...'
        : orders.error != null
        ? '-'
        : null;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 1.46,
      children: [
        _stat(
          'Penjualan hari ini',
          pending ?? rupiah(total),
          null,
          const Color(0xFFECE5D0),
        ),
        _stat(
          'Pesanan',
          pending ?? '${orders.orders.length}',
          null,
          const Color(0xFFB3CEDD),
        ),
        _stat(
          'Produk Terjual',
          pending ?? '$qty',
          null,
          const Color(0xFFFCE9E7),
        ),
        _stat('Stok Menipis', '$low', 'Perlu diisi', const Color(0xFFF8DA7A)),
      ],
    );
  }

  Widget _stat(String label, String value, String? hint, Color color) =>
      Card.filled(
        color: color,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (hint != null)
                Flexible(
                  child: Text(
                    '⚠ $hint',
                    style: const TextStyle(color: Color(0xFFDC043A)),
                  ),
                ),
            ],
          ),
        ),
      );
  Widget _critical(BuildContext context, Produk product) => Card.outlined(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      leading: ProductPhoto(product: product, size: 60),
      title: Text(product.nama),
      subtitle: Text(
        product.stok == 0 ? 'Stok Habis' : 'Sisa ${product.stok}. Segera diisi',
      ),
      trailing: StockBadge(stok: product.stok),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProductEditor(userId: user.id, product: product),
        ),
      ),
    ),
  );
}

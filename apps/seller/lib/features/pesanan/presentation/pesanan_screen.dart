import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../store/presentation/store_widgets.dart';
import '../application/pesanan_provider.dart';
import 'pesanan_widgets.dart';
import 'pesanan_detail_screen.dart';

class PesananScreen extends ConsumerStatefulWidget {
  const PesananScreen({
    super.key,
    required this.userId,
    required this.namaToko,
  });
  final String userId, namaToko;
  @override
  ConsumerState<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends ConsumerState<PesananScreen> {
  String _tab = 'baru';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pesananProvider(widget.userId));
    final orders = state.forTab(_tab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pesanan',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              Text(
                'Toko ${widget.namaToko}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              _tabs(state),
            ],
          ),
        ),
        if (state.error != null)
          PesananError(
            message: state.error!,
            retry: () =>
                ref.read(pesananProvider(widget.userId).notifier).load(),
          ),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(pesananProvider(widget.userId).notifier).load(),
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: orders.isEmpty
                        ? [_empty()]
                        : [for (final order in orders) _card(order, state)],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tabs(PesananState state) => Row(
    children: [
      for (final tab in pesananTabs)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: tab == 'selesai' ? 0 : 8),
            child: Semantics(
              selected: _tab == tab,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _tab == tab
                      ? const Color(0xFF83AC9E)
                      : Colors.white,
                  foregroundColor: _tab == tab ? Colors.white : Colors.black,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => _tab = tab),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_tab == tab) ...[
                      const Icon(Icons.check, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        statusPesanan(tab),
                        key: Key('pesanan-tab-$tab'),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (tab != 'baru')
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Badge.count(
                          key: Key('pesanan-count-$tab'),
                          count: state.forTab(tab).length,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  void _detail(Pesanan order) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PesananDetailScreen(userId: widget.userId, id: order.id),
    ),
  );
  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 18),
    child: Column(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 110,
          color: Color(0xFF7EA895),
        ),
        const SizedBox(height: 24),
        Text(
          'Belum ada pesanan ${_tab == 'baru'
              ? 'baru'
              : _tab == 'diproses'
              ? 'diproses'
              : 'selesai'}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          _tab == 'baru'
              ? 'Pesanan baru akan muncul di sini dan kamu akan dapat notifikasi.'
              : _tab == 'diproses'
              ? 'Pesanan yang diterima akan muncul di sini.'
              : 'Riwayat pesanan akan muncul di sini.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  Widget _card(Pesanan order, PesananState state) => Card.outlined(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _detail(order),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFDCCCAC), width: 8)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.kode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PesananBadge(status: order.status),
                ],
              ),
              Text(
                '${tanggalPesanan(order.createdAt)}, ${jamPesanan(order.createdAt)} - ${order.namaPembeli ?? '-'}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 5),
              for (final item in order.items.take(3))
                Text(
                  '${item.namaSnapshot} x ${item.qty}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (order.items.length > 3) const Text('...'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.slotWaktu,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rupiah(order.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (order.status == 'diproses')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF84ACA3),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                      onPressed: state.busy.contains(order.id)
                          ? null
                          : () async {
                              final result = await ref
                                  .read(pesananProvider(widget.userId).notifier)
                                  .change(
                                    order.id,
                                    () => ref
                                        .read(pesananApiProvider)
                                        .updateStatus(order.id, 'dikemas'),
                                  );
                              if (result == null && mounted) {
                                storeMessage(
                                  context,
                                  ref
                                          .read(pesananProvider(widget.userId))
                                          .error ??
                                      'Status belum berubah.',
                                  error: true,
                                );
                              }
                            },
                      child: const Text('Tandai siap diantar'),
                    ),
                  ),
                ),
              if (pesananTab(order.status) == 'selesai')
                TextButton(
                  onPressed: () => _detail(order),
                  child: const Text('Lihat detail pesanan'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

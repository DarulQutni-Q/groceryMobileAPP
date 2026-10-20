import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../store/presentation/store_widgets.dart';
import '../application/pesanan_provider.dart';
import 'pesanan_actions.dart';
import 'pesanan_widgets.dart';

class PesananDetailScreen extends ConsumerWidget {
  const PesananDetailScreen({
    super.key,
    required this.userId,
    required this.id,
  });
  final String userId, id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pesananDetailProvider((userId: userId, id: id)), (
      previous,
      next,
    ) {
      if (next.hasError &&
          previous?.error != next.error &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        storeMessage(context, authErrorMessage(next.error!), error: true);
      }
    });
    final detail = ref.watch(pesananDetailProvider((userId: userId, id: id)));
    return StorePage(
      title: detail.value?.kode ?? 'Detail Pesanan',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(authErrorMessage(error)),
              TextButton(
                onPressed: () => ref.invalidate(
                  pesananDetailProvider((userId: userId, id: id)),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (order) => _content(context, ref, order),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Pesanan order) => Column(
    children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(pesananDetailProvider((userId: userId, id: id)));
              await ref.read(
                pesananDetailProvider((userId: userId, id: id)).future,
              );
            } catch (error) {
              if (context.mounted) {
                storeMessage(context, authErrorMessage(error), error: true);
              }
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                'Pesanan ${statusPesanan(order.status)}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${tanggalPesanan(order.createdAt)}, ${jamPesanan(order.createdAt)}',
              ),
              const SizedBox(height: 20),
              PesananTimeline(status: order.status),
              const SizedBox(height: 24),
              _buyer(context, order),
              const SizedBox(height: 16),
              _section(
                'Alamat Pengiriman',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.alamatKirim),
                    const SizedBox(height: 10),
                    Text(order.metodeKirim),
                    Text(order.slotWaktu),
                    if (order.catatan?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Catatan: ${order.catatan}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                'Barang Pesanan',
                Column(
                  children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text('${item.namaSnapshot} x ${item.qty}'),
                            ),
                            const SizedBox(width: 10),
                            Text(rupiah(item.hargaSnapshot)),
                          ],
                        ),
                      ),
                    const Divider(),
                    _amount('Subtotal', order.subtotal),
                    _amount('Diskon', -order.diskon),
                    _amount('Ongkir', order.ongkir),
                    _amount('Biaya layanan', order.biayaLayanan),
                    const Divider(),
                    _amount('Total termasuk ongkir', order.total, bold: true),
                  ],
                ),
              ),
              if (order.tolakAlasan != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _section('Alasan penolakan', Text(order.tolakAlasan!)),
                ),
            ],
          ),
        ),
      ),
      _actions(context, ref, order),
    ],
  );
  Widget _section(String title, Widget child) => Card.outlined(
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
  Widget _amount(String label, int amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ),
        Text(
          rupiah(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : null,
            fontSize: bold ? 19 : 14,
          ),
        ),
      ],
    ),
  );
  String _masked(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    if (phone.length < 8) return '****';
    return '${phone.substring(0, 4)} **** ${phone.substring(phone.length - 4)}';
  }

  Widget _buyer(BuildContext context, Pesanan order) => Card.outlined(
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(order.namaPembeli ?? '-'),
      subtitle: Text(_masked(order.teleponPembeli)),
      trailing: IconButton(
        tooltip: order.teleponPembeli == null
            ? 'Nomor telepon belum tersedia'
            : 'Telepon pembeli',
        icon: const Icon(Icons.phone_outlined),
        onPressed: order.teleponPembeli == null
            ? null
            : () => _call(context, order.teleponPembeli!),
      ),
    ),
  );
  Future<void> _call(BuildContext context, String phone) async {
    try {
      final number = phone.replaceAll(RegExp(r'[^+0-9]'), '');
      if (!RegExp(r'^\+?[0-9]{6,15}$').hasMatch(number) ||
          !await launchUrl(Uri(scheme: 'tel', path: number))) {
        if (context.mounted) {
          storeMessage(
            context,
            'Nomor telepon belum dapat dibuka.',
            error: true,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        storeMessage(context, 'Nomor telepon belum dapat dibuka.', error: true);
      }
    }
  }

  Widget _actions(BuildContext context, WidgetRef ref, Pesanan order) {
    final busy = ref.watch(pesananProvider(userId)).busy.contains(id);
    if (pesananTab(order.status) == 'selesai') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.status == 'baru') ...[
            FilledButton(
              onPressed: busy
                  ? null
                  : () => terimaPesanan(context, ref, userId, order),
              child: Text(busy ? 'Memproses...' : 'Terima Pesanan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC043A),
                side: const BorderSide(color: Color(0xFFDC043A)),
              ),
              onPressed: busy ? null : () => tolakPesanan(context, userId, id),
              child: const Text('Tolak Pesanan'),
            ),
          ] else
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final next = switch (order.status) {
                        'diproses' => 'dikemas',
                        'dikemas' => 'diantar',
                        _ => 'selesai',
                      };
                      final result = await ref
                          .read(pesananProvider(userId).notifier)
                          .change(
                            id,
                            () => ref
                                .read(pesananApiProvider)
                                .updateStatus(id, next),
                          );
                      if (!context.mounted) return;
                      if (result != null) {
                        ref.invalidate(
                          pesananDetailProvider((userId: userId, id: id)),
                        );
                      } else if (context.mounted) {
                        storeMessage(
                          context,
                          ref.read(pesananProvider(userId)).error ??
                              'Status belum berubah.',
                          error: true,
                        );
                      }
                    },
              child: Text(
                busy
                    ? 'Memproses...'
                    : switch (order.status) {
                        'diproses' => 'Tandai siap diantar',
                        'dikemas' => 'Mulai antar',
                        _ => 'Tandai tiba',
                      },
              ),
            ),
        ],
      ),
    );
  }
}

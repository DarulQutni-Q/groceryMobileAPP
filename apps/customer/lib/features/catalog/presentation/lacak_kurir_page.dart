import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/pesanan_provider.dart';
import '../application/riwayat_provider.dart';
import 'catalog_page.dart' show CatalogPage;
import 'catalog_widgets.dart' show PromoEmptyState, rupiah;
import 'chat_driver_page.dart' show ChatDriverPage;
import 'pesanan_page.dart' show PesananPage;

/// Halaman khusus tile "Lacak Kurir" di beranda: daftar pesanan dengan
/// pelacak status, bukan sekadar tab Pesanan.
///
/// Label status dan langkah timeline disalin dari PesananPage (satu sumber
/// kebenaran yang sama): langkah Dikonfirmasi / Dikemas / Dalam Perjalanan
/// / Tiba; tidak ada estimasi waktu karena backend tidak punya ETA.
/// Pesanan aktif mendapat tombol "Chat Kurir" ke halaman chat kurir untuk
/// pesanan itu. Pesanan selesai dan dibatalkan/ditolak masuk Riwayat.

bool _isActive(String status) =>
    const {'baru', 'diproses', 'dikemas', 'diantar'}.contains(status);
bool _isDone(String status) => status == 'selesai';

String _statusLabel(String status) => switch (status) {
  'baru' => 'Baru',
  'diproses' => 'Diproses',
  'dikemas' => 'Dikemas',
  'diantar' => 'Diantar',
  'selesai' => 'Selesai',
  'dibatalkan' => 'Dibatalkan',
  'ditolak' => 'Ditolak',
  _ => 'Diproses',
};

String _activeTitle(String status) => switch (status) {
  'baru' => 'Menunggu konfirmasi toko',
  'diproses' => 'Pesanan sedang diproses',
  'dikemas' => 'Pesanan sudah dikemas',
  'diantar' => 'Pesanan dalam perjalanan',
  _ => 'Pesanan dalam proses',
};

/// (langkah selesai, langkah aktif) untuk timeline 4 langkah.
/// aktif -1 berarti semua langkah selesai (pesanan selesai).
(int, int) _timeline(String status) => switch (status) {
  'baru' => (0, 0),
  'diproses' => (1, 1),
  'dikemas' => (2, 2),
  'diantar' => (2, 2),
  'selesai' => (4, -1),
  _ => (0, 0),
};

class _Stepper extends StatelessWidget {
  const _Stepper({required this.status});
  final String status;
  static const _labels = [
    'Dikonfirmasi',
    'Dikemas',
    'Dalam Perjalanan',
    'Tiba',
  ];
  @override
  Widget build(BuildContext context) {
    final (selesai, aktif) = _timeline(status);
    final semuaSelesai = aktif == -1;
    bool nyala(int i) => semuaSelesai || i < selesai || i == aktif;
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < _labels.length; i++) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nyala(i) ? gardenInk : const Color(0xFFD8E2D2),
                ),
              ),
              if (i < _labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: semuaSelesai || i < selesai
                        ? gardenInk
                        : const Color(0xFFD8E2D2),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (int i = 0; i < _labels.length; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: nyala(i) ? gardenInk : textGrey,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final Pesanan order;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = _isActive(order.status);
    final selesai = _isDone(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gardenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.kode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: gardenInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: aktif
                      ? const Color(0xFFE4F3D8)
                      : const Color(0xFFEFF3EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: gardenInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            aktif
                ? _activeTitle(order.status)
                : selesai
                ? 'Pesanan selesai'
                : (order.tolakAlasan ??
                      'Pesanan ${_statusLabel(order.status).toLowerCase()}'),
            style: const TextStyle(fontSize: 12, color: textGrey),
          ),
          if (aktif || selesai) ...[
            const SizedBox(height: 12),
            _Stepper(status: order.status),
          ],
          const SizedBox(height: 12),
          Text(
            '${order.items.length} Barang: '
            '${order.items.map((item) => item.namaSnapshot).join(', ')}',
            style: const TextStyle(fontSize: 12, color: textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${rupiah(order.total)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: gardenInk,
            ),
          ),
          const SizedBox(height: 12),
          _RiwayatStatus(pesananId: order.id),
          if (aktif)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDriverPage(order: order),
                  ),
                ),
                child: const Text('Chat Kurir'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Jejak status dari backend (dengan waktu asli tiap perubahan).
/// Pesanan lama yang dibuat sebelum fitur ini tidak punya baris riwayat:
/// tidak ada yang ditampilkan, dan tidak ada riwayat yang dikarang.
class _RiwayatStatus extends ConsumerWidget {
  const _RiwayatStatus({required this.pesananId});
  final String pesananId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayat = ref.watch(riwayatProvider(pesananId));
    return riwayat.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final terbaruDulu = entries.reversed.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 6),
            for (final entry in terbaruDulu) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF397A24),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(entry.status),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gardenInk,
                          ),
                        ),
                        Text(
                          _waktuRiwayat(entry.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: textGrey,
                          ),
                        ),
                        if (entry.keterangan != null &&
                            entry.keterangan!.isNotEmpty)
                          Text(
                            entry.keterangan!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        );
      },
    );
  }
}

String _waktuRiwayat(DateTime value) {
  final local = value.toLocal();
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${local.day} ${bulan[local.month - 1]} ${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class LacakKurirPage extends ConsumerWidget {
  const LacakKurirPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesanan = ref.watch(pesananProvider);
    return Scaffold(
      body: Column(
        children: [
          const LimeHeader(title: 'Lacak Kurir'),
          Expanded(
            child: pesanan.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(pesananProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return PromoEmptyState(
                    pesan: 'Belum ada pesanan untuk dilacak.',
                    onLihatSemua: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CatalogPage(),
                      ),
                    ),
                  );
                }
                final aktif = orders
                    .where((o) => _isActive(o.status))
                    .toList();
                final riwayat = orders
                    .where((o) => !_isActive(o.status))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (aktif.isNotEmpty) ...[
                      const Text(
                        'Dalam Pengiriman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: gardenInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final o in aktif) _OrderCard(order: o),
                    ],
                    if (riwayat.isNotEmpty) ...[
                      const Text(
                        'Riwayat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: gardenInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final o in riwayat) _OrderCard(order: o),
                    ],
                    TextButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: PesananPage(showBack: true),
                          ),
                        ),
                      ),
                      child: const Text('Buka Pesanan Saya'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/notifikasi_provider.dart';
import 'detail_pesanan_page.dart';

/// Halaman Notifikasi.
///
/// Membaca baris notifikasi tersimpan dari backend: satu baris per
/// perubahan status pesanan. Badge bel di Home memakai provider yang sama,
/// jadi angkanya selalu jumlah belum dibaca di sini.
///
/// Tap kartu menandai dibaca lalu membuka detail pesanannya kalau
/// notifikasi itu terikat ke satu pesanan (pesanan_id). Notifikasi
/// tanpa pesanan (mis. baris lama) tetap hanya ditandai dibaca.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifikasi = ref.watch(notifikasiProvider);
    return Scaffold(
      backgroundColor: authBackground,
      body: Column(
        children: [
          const LimeHeader(
            title: 'Notifikasi',
            centerTitle: false,
            height: 150,
            topPadding: 28,
          ),
          Expanded(
            child: notifikasi.when(
              data: (value) => Column(
                children: [
                  if (value.belumDibaca > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: TextButton(
                          key: const Key('tandai-semua-dibaca'),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(notifikasiApiProvider)
                                  .tandaiSemuaBaca();
                            } catch (_) {
                              // Gagal jaringan: baris tetap belum dibaca,
                              // pengguna bisa menekan lagi.
                            }
                            ref.invalidate(notifikasiProvider);
                          },
                          child: const Text('Tandai semua dibaca'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: value.data.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: value.data.length,
                            itemBuilder: (context, index) {
                              final item = value.data[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: _NotifCard(
                                  key: Key('notif-${item.id}'),
                                  icon: Icons.receipt_long_outlined,
                                  title: item.judul,
                                  subtitle: item.isi,
                                  waktu: _waktu(item.createdAt),
                                  unread: !item.dibaca,
                                  onTap: () async {
                                    if (!item.dibaca) {
                                      try {
                                        await ref
                                            .read(notifikasiApiProvider)
                                            .tandaiBaca(item.id);
                                      } catch (_) {
                                        // Sama seperti di atas: gagal
                                        // jaringan, baris tetap belum dibaca.
                                      }
                                      ref.invalidate(notifikasiProvider);
                                    }
                                    final pesananId = item.pesananId;
                                    if (pesananId != null && context.mounted) {
                                      Navigator.push<void>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailPesananPage(
                                            pesananId: pesananId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(notifikasiProvider),
                  child: const Text('Coba lagi'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _waktu(DateTime t) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final lokal = t.toLocal();
  final jam = lokal.hour.toString().padLeft(2, '0');
  final menit = lokal.minute.toString().padLeft(2, '0');
  return '${lokal.day} ${bulan[lokal.month - 1]}, $jam.$menit';
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.waktu,
    required this.unread,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String waktu;
  final bool unread;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE4F3D8),
                  child: Icon(icon, size: 20, color: gardenInk),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              unread ? FontWeight.w800 : FontWeight.w400,
                          color: gardenInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: textGrey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        waktu,
                        style: const TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: gardenInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: textGrey,
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: textGrey,
              ),
              SizedBox(height: 12),
              Text(
                'Belum ada notifikasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: gardenInk,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Notifikasi perubahan status pesanan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textGrey),
              ),
            ],
          ),
        ),
      );
}

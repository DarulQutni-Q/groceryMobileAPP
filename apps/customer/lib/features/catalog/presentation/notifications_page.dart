import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../checkout/application/checkout_provider.dart';
import '../../checkout/presentation/checkout_page.dart';

/// Halaman Notifikasi.
///
/// Isinya HANYA sinyal nyata dari aplikasi: kartu pembayaran menunggu
/// (dari sesi checkout tersimpan) atau empty state. Badge bel di Home
/// mengikuti jumlah item di sini, tidak ada angka palsu.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCheckoutProvider);
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
            child: pending.when(
              data: (hasPending) => hasPending
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        _NotifCard(
                          key: const Key('notif-pending'),
                          icon: Icons.payment_outlined,
                          title: 'Pembayaran menunggu',
                          subtitle:
                              'Selesaikan pembayaran tersimpan sebelum kedaluwarsa.',
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(items: []),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const _EmptyState(),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(pendingCheckoutProvider),
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

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: gardenInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ),
                ),
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
                'Notifikasi pesanan dan promo akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textGrey),
              ),
            ],
          ),
        ),
      );
}

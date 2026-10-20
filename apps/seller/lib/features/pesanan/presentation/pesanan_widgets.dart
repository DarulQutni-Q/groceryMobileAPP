import 'package:flutter/material.dart';

String jamPesanan(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
}

String tanggalPesanan(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Hari ini';
  if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
  const months = [
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
  return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]}';
}

String statusPesanan(String status) => switch (status) {
  'baru' => 'Baru',
  'diproses' => 'Diproses',
  'dikemas' => 'Dikemas',
  'diantar' => 'Diantar',
  'selesai' => 'Selesai',
  'ditolak' => 'Ditolak',
  'dibatalkan' => 'Dibatalkan',
  _ => status,
};
Color warnaPesanan(String status) => switch (status) {
  'baru' => const Color(0xFFE7B928),
  'diproses' || 'dikemas' || 'diantar' => const Color(0xFFCF9B24),
  'selesai' => const Color(0xFF3B6341),
  'ditolak' => const Color(0xFFDC043A),
  _ => const Color(0xFF777777),
};

class PesananBadge extends StatelessWidget {
  const PesananBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: status == 'baru'
        ? const Icon(
            Icons.notifications_active_outlined,
            size: 16,
            color: Colors.black,
          )
        : null,
    label: Text(statusPesanan(status)),
    backgroundColor: warnaPesanan(status),
    side: BorderSide.none,
    labelStyle: TextStyle(
      color: status == 'baru' ? Colors.black : Colors.white,
      fontSize: 12,
    ),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class PesananError extends StatelessWidget {
  const PesananError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF86361),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: retry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
}

class PesananTimeline extends StatelessWidget {
  const PesananTimeline({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    const labels = ['Diterima', 'Dikemas', 'Diantar', 'Tiba'];
    final active = switch (status) {
      'diproses' => 0,
      'dikemas' => 1,
      'diantar' => 2,
      'selesai' => 3,
      _ => -1,
    };
    return Semantics(
      label: 'Status pesanan ${statusPesanan(status)}',
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 36,
            right: 36,
            child: LinearProgressIndicator(
              value: active < 0 ? 0 : active / 3,
              minHeight: 2,
              color: const Color(0xFF3B6341),
              backgroundColor: const Color(0xFFCDD4C7),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: i <= active
                            ? const Color(0xFF3B6341)
                            : const Color(0xFFE4E7DF),
                        child: Icon(
                          i < active || active == 3
                              ? Icons.check
                              : Icons.circle_outlined,
                          size: 18,
                          color: i <= active ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

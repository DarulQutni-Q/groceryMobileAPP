import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';

/// Halaman Poinku sesuai Figma. Seluruh konten bersifat demo statis dari
/// referensi: backend belum punya endpoint loyalitas, jadi poin 14.850 dan
/// daftar reward ditampilkan apa adanya dan BUKAN data live.
class PoinkuPage extends StatelessWidget {
  const PoinkuPage({super.key});

  /// Poin demo sesuai kartu member di beranda dan referensi.
  static const int poinAktif = 14850;

  static const _rewards = [
    ('Free coffee at Point Coffee', 8000),
    ('Free coffee at Point Coffee', 8000),
    ('Free coffee at Point Coffee', 20000),
    ('Free coffee at Point Coffee', 30000),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    body: Stack(
      children: [
        Column(
          children: [
            ClipPath(
              clipper: GardenWaveClipper(),
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [limeBright, limeLight],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: limeDeep.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poinku',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            RoundIconButton(
                              icon: Icons.question_mark,
                              filled: false,
                              color: Colors.white,
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Poin didapat dari setiap belanja dan dapat ditukar dengan reward di bawah.',
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                children: [
                  const Text(
                    'All Rewards',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  for (final reward in _rewards) ...[
                    _RewardCard(
                      nama: reward.$1,
                      biaya: reward.$2,
                      poin: poinAktif,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 130,
          left: 20,
          right: 20,
          child: Card(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.star, size: 36, color: scanYellow),
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Icon(Icons.star, size: 12, color: scanYellow),
                      ),
                      Positioned(
                        left: -4,
                        bottom: -2,
                        child: Icon(Icons.star, size: 10, color: scanYellow),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POINKU AKTIF',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        Text(
                          '14.850 Poin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+250 poin baru',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5E872F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Riwayat Poin'),
                        content: const Text(
                          'Riwayat poin belum tersedia di GardenMart karena '
                          'backend belum menyediakan data loyalitas.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: limeBright,
                      foregroundColor: gardenInk,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    child: const Text('History'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Satu kartu reward: lingkaran hijau, nama, progress poin/biaya, tombol
/// Tukar kalau poin cukup, ikon gembok kalau belum cukup.
class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.nama,
    required this.biaya,
    required this.poin,
  });
  final String nama;
  final int biaya;
  final int poin;

  @override
  Widget build(BuildContext context) {
    final cukup = poin >= biaya;
    final progress = (poin / biaya).clamp(0.0, 1.0);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF1E7A34),
                shape: BoxShape.circle,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_cafe, color: Colors.white, size: 28),
                  Text(
                    'POINT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$biaya Points',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E872F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (cukup)
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Penukaran Poin'),
                        content: const Text(
                          'Penukaran poin belum tersedia di GardenMart '
                          'karena backend belum menyediakan penukaran poin.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: gardenInk,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    child: const Text('Tukar'),
                  )
                else
                  const SizedBox(height: 32),
                const SizedBox(height: 6),
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Colors.black45,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

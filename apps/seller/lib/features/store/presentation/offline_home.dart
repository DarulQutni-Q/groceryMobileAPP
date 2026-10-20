import 'package:flutter/material.dart';

import '../../../shared/auth_layout.dart';

class OfflineHome extends StatelessWidget {
  const OfflineHome({
    super.key,
    required this.namaToko,
    required this.retry,
    required this.loading,
  });
  final String namaToko;
  final VoidCallback retry;
  final bool loading;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
    children: [
      const Text(
        'Beranda',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
      ),
      Text('Toko $namaToko', style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 22),
      Card.filled(
        margin: EdgeInsets.zero,
        color: const Color(0xFFF86361),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tidak ada koneksi internet',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 60),
      const Center(
        child: SizedBox(
          width: 170,
          height: 170,
          child: ClipOval(
            child: ReferenceArtwork(
              asset: 'beranda-offline.png',
              rect: Rect.fromLTWH(159, 338, 152, 152),
              width: 170,
              semanticLabel: 'Ilustrasi koneksi terputus',
            ),
          ),
        ),
      ),
      const SizedBox(height: 26),
      const Text(
        'Belum bisa memuat data',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      const Text(
        'Periksa koneksi internet atau Wi-Fi, lalu coba lagi.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      Center(
        child: SizedBox(
          width: 300,
          child: FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 58),
              textStyle: const TextStyle(fontSize: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: loading ? null : retry,
            child: Text(loading ? 'Memuat...' : 'Coba lagi'),
          ),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class RingkasanPage extends StatefulWidget {
  const RingkasanPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<RingkasanPage> createState() => _RingkasanPageState();
}

class _RingkasanPageState extends State<RingkasanPage> {
  Map<String, dynamic>? _data;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final data = await widget.api.ringkasan();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (sesiHabis(error)) {
        widget.onUnauthorized();
        return;
      }
      if (mounted) {
        setState(() => _galat = AdminApi.pesanGalat(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_galat != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_galat!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _muat, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final perStatus =
        Map<String, dynamic>.from(data['pesanan_per_status'] as Map);
    final perRole = Map<String, dynamic>.from(data['pengguna_per_role'] as Map);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _muat,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            KartuStat(
              judul: 'Pengguna',
              nilai: '${data['pengguna_total']}',
              subjudul: perRole.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('  •  '),
            ),
            KartuStat(
              judul: 'Toko buka',
              nilai: '${data['toko_buka']} / ${data['toko_total']}',
            ),
            KartuStat(
              judul: 'Pesanan total',
              nilai: '${data['pesanan_total']}',
              subjudul: 'Hari ini: ${data['pesanan_hari_ini']}',
            ),
            KartuStat(
              judul: 'Omzet selesai 7 hari',
              nilai: rupiah(data['omzet_selesai_7h'] as int),
            ),
            KartuStat(
              judul: 'Omzet selesai 30 hari',
              nilai: rupiah(data['omzet_selesai_30h'] as int),
            ),
            KartuStat(
              judul: 'Baru lewat 70 menit',
              nilai: '${data['baru_lewat_70_menit']}',
              subjudul: 'Kandidat sweeper pesanan tak dibayar',
            ),
            KartuStat(
              judul: 'Token FCM perangkat',
              nilai: '${data['token_fcm_total']}',
              subjudul: 'Nol berarti push asli belum bisa dites',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Pesanan per status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: perStatus.entries
              .map(
                (e) => Chip(
                  label: Text('${labelStatus(e.key)}: ${e.value}'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

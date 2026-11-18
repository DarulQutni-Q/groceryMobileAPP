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
    final perBayar =
        Map<String, dynamic>.from(data['pembayaran_per_status'] as Map);
    final sempit = MediaQuery.sizeOf(context).width < 600;
    final kartu = <Widget>[
      KartuStat(
        judul: 'Pengguna',
        nilai: '${data['pengguna_total']}',
        lebar: 220,
        subjudul:
            perRole.entries.map((e) => '${e.key}: ${e.value}').join('  •  '),
      ),
      KartuStat(
        judul: 'Toko buka',
        nilai: '${data['toko_buka']} / ${data['toko_total']}',
        lebar: 220,
      ),
      KartuStat(
        judul: 'Pesanan total',
        nilai: '${data['pesanan_total']}',
        lebar: 220,
        subjudul: 'Hari ini: ${data['pesanan_hari_ini']}',
      ),
      KartuStat(
        judul: 'Omzet selesai 7 hari',
        nilai: rupiah(data['omzet_selesai_7h'] as int),
        lebar: 220,
      ),
      KartuStat(
        judul: 'Omzet selesai 30 hari',
        nilai: rupiah(data['omzet_selesai_30h'] as int),
        lebar: 220,
      ),
      KartuStat(
        judul: 'Produk',
        nilai: '${data['produk_total']}',
        lebar: 220,
      ),
      KartuStat(
        judul: 'Pembayaran',
        nilai: '${data['pembayaran_total']}',
        lebar: 220,
        subjudul: perBayar.entries
            .map((e) => '${labelPembayaran(e.key)}: ${e.value}')
            .join('  •  '),
      ),
      KartuStat(
        judul: 'Baru lewat 70 menit',
        nilai: '${data['baru_lewat_70_menit']}',
        lebar: 220,
        subjudul: 'Kandidat sweeper pesanan tak dibayar',
      ),
      KartuStat(
        judul: 'Token FCM perangkat',
        nilai: '${data['token_fcm_total']}',
        lebar: 220,
        subjudul: 'Nol berarti push asli belum bisa dites',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
        if (sempit)
          for (var i = 0; i < kartu.length; i++) ...[
            SizedBox(width: double.infinity, child: kartu[i]),
            if (i < kartu.length - 1) const SizedBox(height: 12),
          ]
        else
          Wrap(spacing: 12, runSpacing: 12, children: kartu),
        const SizedBox(height: 24),
        const Text(
          'Pesanan per status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
        const SizedBox(height: 24),
        const Text(
          'Pembayaran per status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: perBayar.entries
              .map(
                (e) => Chip(
                  label: Text('${labelPembayaran(e.key)}: ${e.value}'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

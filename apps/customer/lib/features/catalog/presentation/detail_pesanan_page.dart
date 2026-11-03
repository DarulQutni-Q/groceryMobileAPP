import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/pesanan_provider.dart';
import 'catalog_widgets.dart';

const _statusJudul = {
  'baru': 'Baru',
  'diproses': 'Diproses',
  'dikemas': 'Dikemas',
  'diantar': 'Diantar',
  'selesai': 'Selesai',
  'dibatalkan': 'Dibatalkan',
  'ditolak': 'Ditolak',
};

const _statusAktif = {'baru', 'diproses', 'dikemas', 'diantar'};

/// Detail satu pesanan, dibuka dari tap notifikasi. Semua data dari
/// backend (detail + riwayat status); tidak ada status yang dikarang.
class DetailPesananPage extends ConsumerStatefulWidget {
  const DetailPesananPage({super.key, required this.pesananId});

  final String pesananId;

  @override
  ConsumerState<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends ConsumerState<DetailPesananPage> {
  Pesanan? _pesanan;
  List<RiwayatStatus> _riwayat = [];
  bool _memuat = true;
  bool _gagal = false;
  bool _membatalkan = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _gagal = false;
    });
    try {
      final api = ref.read(pesananApiProvider);
      final pesanan = await api.detail(widget.pesananId);
      var riwayat = <RiwayatStatus>[];
      try {
        riwayat = await api.riwayat(widget.pesananId);
      } catch (_) {
        // Riwayat kosong untuk pesanan lama bukan kegagalan halaman.
        riwayat = [];
      }
      if (!mounted) return;
      setState(() {
        _pesanan = pesanan;
        _riwayat = riwayat;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gagal = true;
        _memuat = false;
      });
    }
  }

  Future<void> _batalkan() async {
    final pesanan = _pesanan;
    if (pesanan == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan pesanan ${pesanan.kode}?'),
        content: const Text(
          'Pesanan yang dibatalkan tidak bisa dikembalikan. '
          'Kalau pesanan sudah dibayar, pengembalian dana diproses manual oleh toko.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dangerRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _membatalkan = true);
    try {
      await ref.read(pesananApiProvider).batalkan(pesanan.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _membatalkan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membatalkan pesanan, coba lagi.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pesanan ${pesanan.kode} dibatalkan.')),
    );
    ref.invalidate(pesananProvider);
    await _muat();
    if (mounted) setState(() => _membatalkan = false);
  }

  @override
  Widget build(BuildContext context) {
    final pesanan = _pesanan;
    return Scaffold(
      backgroundColor: authBackground,
      body: Column(
        children: [
          LimeHeader(
            title: pesanan == null ? 'Detail Pesanan' : 'Pesanan ${pesanan.kode}',
            height: 150,
            topPadding: 28,
          ),
          Expanded(
            child: _memuat
                ? const Center(child: CircularProgressIndicator())
                : _gagal || pesanan == null
                    ? Center(
                        child: TextButton(
                          onPressed: _muat,
                          child: const Text('Coba lagi'),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          _Kartu(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusJudul[pesanan.status] ?? pesanan.status,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: gardenInk,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pesanan.metodeKirim} • ${pesanan.slotWaktu}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textGrey,
                                  ),
                                ),
                                if (pesanan.tolakAlasan != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Alasan penolakan: ${pesanan.tolakAlasan}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: dangerRed,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_riwayat.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _Kartu(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Riwayat Status',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: gardenInk,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (var i = 0; i < _riwayat.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(top: 3),
                                          decoration: const BoxDecoration(
                                            color: resetGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _statusJudul[_riwayat[i].status] ??
                                                _riwayat[i].status,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: gardenInk,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _waktu(_riwayat[i].createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _Kartu(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Isi Pesanan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: gardenInk,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final item in pesanan.items) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.namaSnapshot} x${item.qty}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: gardenInk,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        rupiah(item.hargaSnapshot * item.qty),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: gardenInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                const Divider(),
                                _BarisBiaya(
                                  'Subtotal',
                                  rupiah(pesanan.subtotal),
                                ),
                                _BarisBiaya(
                                  'Diskon',
                                  pesanan.diskon > 0
                                      ? '-${rupiah(pesanan.diskon)}'
                                      : rupiah(0),
                                ),
                                _BarisBiaya(
                                  'Ongkos Kirim',
                                  rupiah(pesanan.ongkir),
                                ),
                                _BarisBiaya(
                                  'Biaya Layanan',
                                  rupiah(pesanan.biayaLayanan),
                                ),
                                const Divider(),
                                _BarisBiaya(
                                  'Total',
                                  rupiah(pesanan.total),
                                  tebal: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Kartu(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alamat Pengiriman',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: gardenInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pesanan.alamatKirim,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: gardenInk,
                                  ),
                                ),
                                if (pesanan.catatan != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Catatan: ${pesanan.catatan}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_statusAktif.contains(pesanan.status)) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                key: Key('detail-batalkan-${pesanan.id}'),
                                onPressed: _membatalkan ? null : _batalkan,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: dangerRed,
                                  side: const BorderSide(color: dangerRed),
                                ),
                                child: const Text('Batalkan pesanan'),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

String _waktu(DateTime t) {
  final lokal = t.toLocal();
  final jam = lokal.hour.toString().padLeft(2, '0');
  final menit = lokal.minute.toString().padLeft(2, '0');
  return '${lokal.day}/${lokal.month}/${lokal.year} $jam.$menit';
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _BarisBiaya extends StatelessWidget {
  const _BarisBiaya(this.label, this.nilai, {this.tebal = false});
  final String label;
  final String nilai;
  final bool tebal;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tebal ? FontWeight.w800 : FontWeight.w400,
                color: gardenInk,
              ),
            ),
          ),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 13,
              fontWeight: tebal ? FontWeight.w800 : FontWeight.w400,
              color: gardenInk,
            ),
          ),
        ],
      ),
    );
  }
}

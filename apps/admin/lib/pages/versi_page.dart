import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class VersiKesehatanPage extends StatefulWidget {
  const VersiKesehatanPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<VersiKesehatanPage> createState() => _VersiKesehatanPageState();
}

class _VersiKesehatanPageState extends State<VersiKesehatanPage> {
  Map<String, dynamic>? _versi;
  Map<String, dynamic>? _sehat;
  String? _galat;
  final _customer = TextEditingController();
  final _seller = TextEditingController();
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _customer.dispose();
    _seller.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final versi = await widget.api.versiMinimum();
      final sehat = await widget.api.kesehatan();
      if (mounted) {
        setState(() {
          _versi = versi;
          _sehat = sehat;
          _customer.text = versi['customer'] as String;
          _seller.text = versi['seller'] as String;
          _galat = null;
        });
      }
    } catch (error) {
      if (sesiHabis(error)) {
        widget.onUnauthorized();
        return;
      }
      if (mounted) setState(() => _galat = AdminApi.pesanGalat(error));
    }
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      final versi = await widget.api.ubahVersiMinimum(
        customer: _customer.text.trim(),
        seller: _seller.text.trim(),
      );
      if (mounted) {
        setState(() {
          _versi = versi;
          _menyimpan = false;
        });
        pesan(context, 'Versi minimum tersimpan.');
      }
    } catch (error) {
      if (sesiHabis(error)) {
        widget.onUnauthorized();
        return;
      }
      if (mounted) {
        setState(() => _menyimpan = false);
        pesan(context, AdminApi.pesanGalat(error) ?? 'Gagal menyimpan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Versi & Kesehatan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (_galat != null)
          Text(_galat!, style: const TextStyle(color: Colors.red))
        else if (_versi == null || _sehat == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          const Text(
            'Versi minimum (force-update)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Nilai dari database mengalahkan environment. '
            'Sumber sekarang: customer ${_versi!['customer_sumber']}, '
            'seller ${_versi!['seller_sumber']}.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _customer,
                  decoration: const InputDecoration(
                    labelText: 'Customer (mis. 0.1.0)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _seller,
                  decoration: const InputDecoration(
                    labelText: 'Seller (mis. 1.0.0)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    isDense: true,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _menyimpan ? null : _simpan,
                child: const Text('Simpan versi'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Kesehatan sistem',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KartuStat(
                judul: 'Database',
                nilai: _sehat!['database'] as String,
              ),
              KartuStat(
                judul: 'SMTP terkonfigurasi',
                nilai: (_sehat!['smtp_terkonfigurasi'] as bool)
                    ? 'Ya'
                    : 'Tidak',
              ),
              KartuStat(
                judul: 'File FCM ada',
                nilai: (_sehat!['fcm_file_ada'] as bool) ? 'Ya' : 'Tidak',
              ),
              KartuStat(
                judul: 'Token FCM perangkat',
                nilai: '${_sehat!['token_fcm_total']}',
              ),
              KartuStat(
                judul: 'Sweeper terakhir jalan',
                nilai: tanggal(
                  _sehat!['sweeper_terakhir_jalan'] as String?,
                ),
                subjudul: _sehat!['sweeper_jumlah_terakhir'] == null
                    ? 'Belum pernah sejak server start'
                    : 'Membatalkan ${_sehat!['sweeper_jumlah_terakhir']} pesanan',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

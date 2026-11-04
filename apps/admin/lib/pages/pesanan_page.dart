import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

const _semuaStatus = [
  'baru',
  'diproses',
  'dikemas',
  'diantar',
  'selesai',
  'dibatalkan',
  'ditolak',
];

class PesananPage extends StatefulWidget {
  const PesananPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  List<dynamic> _rows = [];
  Map<String, dynamic> _meta = {};
  String? _galat;
  String? _status;
  final _cari = TextEditingController();
  var _page = 1;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  Map<String, String> _filterPesanan() {
    final filter = <String, String>{};
    if (_status != null) filter['status'] = _status!;
    if (_cari.text.trim().isNotEmpty) filter['q'] = _cari.text.trim();
    return filter;
  }

  Future<void> _muat() async {
    try {
      final hasil = await widget.api.daftar(
        '/admin/pesanan',
        page: _page,
        filter: _filterPesanan(),
      );
      if (mounted) {
        setState(() {
          _rows = List<dynamic>.from(hasil['data'] as List);
          _meta = Map<String, dynamic>.from(hasil['meta'] as Map);
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

  void _tampilDetail(Map<String, dynamic> order) {
    final items = List<dynamic>.from(order['items'] as List? ?? []);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pesanan #${order['kode']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${labelStatus(order['status'] as String)}'),
              Text('Toko: ${order['toko_id']}'),
              Text('Alamat: ${order['alamat_kirim']}'),
              Text('Total: ${rupiah(order['total'] as int)}'),
              const SizedBox(height: 12),
              const Text('Isi pesanan:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final item in items)
                Text(
                  '- ${item['nama_snapshot']} x${item['qty']} '
                  '(${rupiah(item['harga_snapshot'] as int)})',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _meta['total_pages'] as int? ?? 1;
    final total = _meta['total'] as int? ?? _rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pesanan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: _status,
              hint: const Text('Semua status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua status')),
                for (final s in _semuaStatus)
                  DropdownMenuItem(value: s, child: Text(labelStatus(s))),
              ],
              onChanged: (v) => setState(() {
                _status = v;
                _page = 1;
                _muat();
              }),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _cari,
                decoration: const InputDecoration(
                  labelText: 'Cari kode pesanan',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => setState(() {
                  _page = 1;
                  _muat();
                }),
              ),
            ),
            FilledButton(onPressed: _muat, child: const Text('Cari')),
          ],
        ),
        const SizedBox(height: 16),
        if (_galat != null)
          Text(_galat!, style: const TextStyle(color: Colors.red))
        else if (_rows.isEmpty)
          const Text('Belum ada pesanan yang cocok.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Kode')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Dibuat')),
                DataColumn(label: Text('')),
              ],
              rows: _rows.map((row) {
                final order = Map<String, dynamic>.from(row as Map);
                return DataRow(
                  cells: [
                    DataCell(Text(order['kode'] as String)),
                    DataCell(Text(labelStatus(order['status'] as String))),
                    DataCell(Text(rupiah(order['total'] as int))),
                    DataCell(Text(tanggal(order['created_at'] as String?))),
                    DataCell(
                      TextButton(
                        onPressed: () => _tampilDetail(order),
                        child: const Text('Detail'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        BarisPaginasi(
          page: _page,
          totalPages: totalPages,
          total: total,
          onPage: (p) => setState(() {
            _page = p;
            _muat();
          }),
        ),
      ],
    );
  }
}

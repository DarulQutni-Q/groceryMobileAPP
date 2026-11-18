import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

const _semuaStatusBayar = ['paid', 'pending', 'expired', 'failed'];

const _semuaMetode = [
  'qris',
  'gopay',
  'shopeepay',
  'va_bca',
  'va_bri',
  'va_mandiri',
  'cod',
];

class PembayaranPage extends StatefulWidget {
  const PembayaranPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  List<dynamic> _rows = [];
  Map<String, dynamic> _meta = {};
  String? _galat;
  String? _status;
  String? _metode;
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

  Map<String, String> _filterPembayaran() {
    final filter = <String, String>{};
    if (_status != null) filter['status'] = _status!;
    if (_metode != null) filter['metode'] = _metode!;
    if (_cari.text.trim().isNotEmpty) filter['q'] = _cari.text.trim();
    return filter;
  }

  Future<void> _muat() async {
    try {
      final hasil = await widget.api.daftar(
        '/admin/pembayaran',
        page: _page,
        filter: _filterPembayaran(),
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

  void _tampilDetail(Map<String, dynamic> bayar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pembayaran ${bayar['pesanan_kode'] as String? ?? '-'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pesanan: ${bayar['pesanan_kode'] as String? ?? '-'}'),
              Text('Metode: ${labelMetode(bayar['metode'] as String)}'),
              Text('Status: ${labelPembayaran(bayar['status'] as String)}'),
              Text('Jumlah: ${rupiah(bayar['jumlah'] as int)}'),
              Text('Dibayar: ${tanggal(bayar['paid_at'] as String?)}'),
              Text(
                'Perlu rekonsiliasi: '
                '${(bayar['perlu_rekonsiliasi'] as bool) ? 'Ya' : 'Tidak'}',
              ),
              Text('Dibuat: ${tanggal(bayar['created_at'] as String?)}'),
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
    final sempit = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                for (final s in _semuaStatusBayar)
                  DropdownMenuItem(value: s, child: Text(labelPembayaran(s))),
              ],
              onChanged: (v) => setState(() {
                _status = v;
                _page = 1;
                _muat();
              }),
            ),
            DropdownButton<String?>(
              value: _metode,
              hint: const Text('Semua metode'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua metode')),
                for (final m in _semuaMetode)
                  DropdownMenuItem(value: m, child: Text(labelMetode(m))),
              ],
              onChanged: (v) => setState(() {
                _metode = v;
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
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
          const Text('Belum ada pembayaran yang cocok.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Pesanan')),
                const DataColumn(label: Text('Metode')),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('Jumlah')),
                if (!sempit) const DataColumn(label: Text('Dibayar')),
                const DataColumn(label: Text('')),
              ],
              rows: _rows.map((row) {
                final bayar = Map<String, dynamic>.from(row as Map);
                return DataRow(
                  cells: [
                    DataCell(
                        Text(bayar['pesanan_kode'] as String? ?? '-')),
                    DataCell(Text(labelMetode(bayar['metode'] as String))),
                    DataCell(
                        Text(labelPembayaran(bayar['status'] as String))),
                    DataCell(Text(rupiah(bayar['jumlah'] as int))),
                    if (!sempit)
                      DataCell(
                          Text(tanggal(bayar['paid_at'] as String?))),
                    DataCell(
                      TextButton(
                        onPressed: () => _tampilDetail(bayar),
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

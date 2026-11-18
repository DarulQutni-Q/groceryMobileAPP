import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  List<dynamic> _rows = [];
  Map<String, dynamic> _meta = {};
  String? _galat;
  String? _tokoId;
  List<Map<String, dynamic>> _toko = [];
  final _cari = TextEditingController();
  var _page = 1;

  @override
  void initState() {
    super.initState();
    _muatToko();
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muatToko() async {
    try {
      final hasil = await widget.api.daftar('/admin/toko', perPage: 100);
      if (mounted) {
        setState(() {
          _toko = (hasil['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (error) {
      if (sesiHabis(error)) {
        widget.onUnauthorized();
      }
      // Daftar toko gagal: filter toko tidak tampil, daftar produk tetap jalan.
    }
  }

  Map<String, String> _filterProduk() {
    final filter = <String, String>{};
    if (_tokoId != null) filter['toko_id'] = _tokoId!;
    if (_cari.text.trim().isNotEmpty) filter['q'] = _cari.text.trim();
    return filter;
  }

  Future<void> _muat() async {
    try {
      final hasil = await widget.api.daftar(
        '/admin/produk',
        page: _page,
        filter: _filterProduk(),
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

  void _tampilDetail(Map<String, dynamic> produk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(produk['nama'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toko: ${produk['toko_nama'] as String? ?? '-'}'),
              Text('Kategori: ${produk['kategori']}'),
              Text('Harga: ${rupiah(produk['harga'] as int)}'),
              Text('Stok: ${produk['stok']} ${produk['satuan']}'),
              Text(
                'Tersedia: ${(produk['is_tersedia'] as bool) ? 'Ya' : 'Tidak'}',
              ),
              Text('Dibuat: ${tanggal(produk['created_at'] as String?)}'),
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
          'Produk',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: _tokoId,
              hint: const Text('Semua toko'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua toko')),
                for (final toko in _toko)
                  DropdownMenuItem(
                    value: toko['id'] as String,
                    child: Text(toko['nama'] as String),
                  ),
              ],
              onChanged: (v) => setState(() {
                _tokoId = v;
                _page = 1;
                _muat();
              }),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _cari,
                decoration: const InputDecoration(
                  labelText: 'Cari nama produk',
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
          const Text('Belum ada produk yang cocok.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Nama')),
                if (!sempit) const DataColumn(label: Text('Toko')),
                const DataColumn(label: Text('Harga')),
                const DataColumn(label: Text('Stok')),
                if (!sempit) const DataColumn(label: Text('Kategori')),
                const DataColumn(label: Text('')),
              ],
              rows: _rows.map((row) {
                final produk = Map<String, dynamic>.from(row as Map);
                return DataRow(
                  cells: [
                    DataCell(Text(produk['nama'] as String)),
                    if (!sempit)
                      DataCell(
                          Text(produk['toko_nama'] as String? ?? '-')),
                    DataCell(Text(rupiah(produk['harga'] as int))),
                    DataCell(
                      Text('${produk['stok']} ${produk['satuan']}'),
                    ),
                    if (!sempit)
                      DataCell(Text(produk['kategori'] as String)),
                    DataCell(
                      TextButton(
                        onPressed: () => _tampilDetail(produk),
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

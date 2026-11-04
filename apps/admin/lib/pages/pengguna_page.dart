import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  List<dynamic> _rows = [];
  Map<String, dynamic> _meta = {};
  String? _galat;
  String? _role;
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

  Map<String, String> _filterPengguna() {
    final filter = <String, String>{};
    if (_role != null) filter['role'] = _role!;
    if (_cari.text.trim().isNotEmpty) filter['q'] = _cari.text.trim();
    return filter;
  }

  Future<void> _muat() async {
    try {
      final hasil = await widget.api.daftar(
        '/admin/pengguna',
        page: _page,
        filter: _filterPengguna(),
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

  Future<void> _hapus(Map<String, dynamic> user) async {
    final setuju = await konfirmasi(
      context,
      'Hapus pengguna',
      'Hapus ${user['nama']} (${user['email']})? Akun dengan toko atau '
          'riwayat pesanan ditolak server.',
    );
    if (!setuju) return;
    try {
      await widget.api.hapusPengguna(user['id'] as String);
      if (mounted) {
        pesan(context, 'Pengguna ${user['email']} dihapus.');
        _muat();
      }
    } catch (error) {
      if (sesiHabis(error)) {
        widget.onUnauthorized();
        return;
      }
      if (mounted) pesan(context, AdminApi.pesanGalat(error) ?? 'Gagal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _meta['total_pages'] as int? ?? 1;
    final total = _meta['total'] as int? ?? _rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengguna',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: _role,
              hint: const Text('Semua role'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua role')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'seller', child: Text('Seller')),
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
              ],
              onChanged: (v) => setState(() {
                _role = v;
                _page = 1;
                _muat();
              }),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _cari,
                decoration: const InputDecoration(
                  labelText: 'Cari nama atau email',
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
          const Text('Belum ada pengguna yang cocok.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nama')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Toko')),
                DataColumn(label: Text('Pesanan')),
                DataColumn(label: Text('')),
              ],
              rows: _rows.map((row) {
                final user = Map<String, dynamic>.from(row as Map);
                return DataRow(
                  cells: [
                    DataCell(Text(user['nama'] as String)),
                    DataCell(Text(user['email'] as String)),
                    DataCell(Text(user['role'] as String)),
                    DataCell(Text(user['toko_nama'] as String? ?? '-')),
                    DataCell(Text('${user['pesanan_total']}')),
                    DataCell(
                      TextButton(
                        onPressed: () => _hapus(user),
                        child: const Text('Hapus'),
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

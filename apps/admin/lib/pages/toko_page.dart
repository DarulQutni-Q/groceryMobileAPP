import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

class TokoPage extends StatefulWidget {
  const TokoPage({super.key, required this.api, required this.onUnauthorized});

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<TokoPage> createState() => _TokoPageState();
}

class _TokoPageState extends State<TokoPage> {
  List<dynamic> _rows = [];
  Map<String, dynamic> _meta = {};
  String? _galat;
  String? _status;
  var _page = 1;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final hasil = await widget.api.daftar(
        '/admin/toko',
        page: _page,
        filter: _status == null ? null : {'status': _status!},
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

  Future<void> _toggleStatus(Map<String, dynamic> toko) async {
    final baru = toko['status'] == 'buka' ? 'tutup' : 'buka';
    final setuju = await konfirmasi(
      context,
      'Ubah status toko',
      'Ubah ${toko['nama']} menjadi $baru?',
    );
    if (!setuju) return;
    try {
      await widget.api.ubahStatusToko(toko['id'] as String, baru);
      if (mounted) {
        pesan(context, 'Status ${toko['nama']} menjadi $baru.');
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
    final sempit = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toko',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButton<String?>(
          value: _status,
          hint: const Text('Semua status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua status')),
            DropdownMenuItem(value: 'buka', child: Text('Buka')),
            DropdownMenuItem(value: 'tutup', child: Text('Tutup')),
          ],
          onChanged: (v) => setState(() {
            _status = v;
            _page = 1;
            _muat();
          }),
        ),
        const SizedBox(height: 16),
        if (_galat != null)
          Text(_galat!, style: const TextStyle(color: Colors.red))
        else if (_rows.isEmpty)
          const Text('Belum ada toko.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Nama')),
                if (!sempit) const DataColumn(label: Text('Alamat')),
                if (!sempit) const DataColumn(label: Text('Telepon')),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('')),
              ],
              rows: _rows.map((row) {
                final toko = Map<String, dynamic>.from(row as Map);
                final buka = toko['status'] == 'buka';
                return DataRow(
                  cells: [
                    DataCell(Text(toko['nama'] as String)),
                    if (!sempit) DataCell(Text(toko['alamat'] as String)),
                    if (!sempit) DataCell(Text(toko['telepon'] as String)),
                    DataCell(Text(buka ? 'Buka' : 'Tutup')),
                    DataCell(
                      TextButton(
                        onPressed: () => _toggleStatus(toko),
                        child: Text(buka ? 'Tutup toko' : 'Buka toko'),
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

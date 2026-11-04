import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class VoucherPromoPage extends StatefulWidget {
  const VoucherPromoPage({
    super.key,
    required this.api,
    required this.onUnauthorized,
  });

  final AdminApi api;
  final VoidCallback onUnauthorized;

  @override
  State<VoucherPromoPage> createState() => _VoucherPromoPageState();
}

class _VoucherPromoPageState extends State<VoucherPromoPage> {
  List<dynamic> _voucher = [];
  List<dynamic> _promo = [];
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final v = await widget.api.daftar('/admin/voucher', perPage: 50);
      final p = await widget.api.daftar('/admin/promo', perPage: 50);
      if (mounted) {
        setState(() {
          _voucher = List<dynamic>.from(v['data'] as List);
          _promo = List<dynamic>.from(p['data'] as List);
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

  @override
  Widget build(BuildContext context) {
    final sempit = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voucher & Promo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tampilan baca saja lintas toko. Pembuatan dan ubah voucher '
          'dan promo tetap lewat app seller pemilik toko.',
        ),
        const SizedBox(height: 16),
        if (_galat != null)
          Text(_galat!, style: const TextStyle(color: Colors.red))
        else ...[
          const Text(
            'Voucher',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_voucher.isEmpty)
            const Text('Belum ada voucher.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Kode')),
                  const DataColumn(label: Text('Judul')),
                  const DataColumn(label: Text('Persen')),
                  if (!sempit) const DataColumn(label: Text('Min. belanja')),
                  if (!sempit) const DataColumn(label: Text('Cap')),
                  const DataColumn(label: Text('Aktif')),
                ],
                rows: _voucher.map((row) {
                  final v = Map<String, dynamic>.from(row as Map);
                  return DataRow(
                    cells: [
                      DataCell(Text(v['kode'] as String)),
                      DataCell(Text(v['judul'] as String)),
                      DataCell(Text('${v['persen']}%')),
                      if (!sempit)
                        DataCell(Text(rupiah(v['min_belanja'] as int))),
                      if (!sempit) DataCell(Text(rupiah(v['cap'] as int))),
                      DataCell(Text((v['aktif'] as bool) ? 'Ya' : 'Tidak')),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Promo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_promo.isEmpty)
            const Text('Belum ada promo.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Judul')),
                  const DataColumn(label: Text('Jenis')),
                  const DataColumn(label: Text('Harga promo')),
                  if (!sempit) const DataColumn(label: Text('Min. belanja')),
                  const DataColumn(label: Text('Aktif')),
                  if (!sempit) const DataColumn(label: Text('Berakhir')),
                ],
                rows: _promo.map((row) {
                  final p = Map<String, dynamic>.from(row as Map);
                  return DataRow(
                    cells: [
                      DataCell(Text(p['judul'] as String)),
                      DataCell(Text(p['jenis'] as String)),
                      DataCell(Text(rupiah(p['harga_promo'] as int))),
                      if (!sempit)
                        DataCell(Text(rupiah(p['min_belanja'] as int))),
                      DataCell(Text((p['aktif'] as bool) ? 'Ya' : 'Tidak')),
                      if (!sempit)
                        DataCell(
                          Text(tanggal(p['berakhir_at'] as String?)),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}

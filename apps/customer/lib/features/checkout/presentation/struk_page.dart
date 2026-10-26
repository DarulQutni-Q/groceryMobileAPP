import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/auth_artwork.dart';

/// Data struk belanja. Nilai default = contoh struk pada desain Figma.
class StrukItem {
  const StrukItem({
    required this.nama,
    required this.qty,
    required this.hargaSatuan,
    required this.total,
    this.hargaCoret,
    this.hemat,
  });
  final String nama;
  final String qty;
  final String hargaSatuan;
  final String total;
  final String? hargaCoret;
  final String? hemat;
}

class StrukData {
  const StrukData({
    this.nomor = '#GM-8921-20261003',
    this.waktu = '3 Okt 2026, 14:28 WIB',
    this.kasir = 'Rani (Counter 02)',
    this.kurir = 'Pak Budi (Motor)',
    this.items = const [
      StrukItem(
        nama: 'Bimoli Minyak Goreng 2L Pouch',
        qty: '1x @ Rp 33.900',
        hargaSatuan: 'Rp 33.900',
        total: 'Rp 33.900',
      ),
      StrukItem(
        nama: 'Ultra Milk UHT Cokelat 1000ml',
        qty: '2x @ Rp 17.500',
        hargaSatuan: 'Rp 35.000',
        total: 'Rp 35.000',
        hargaCoret: 'Rp 49.900',
        hemat: 'Hemat Rp 8.800',
      ),
      StrukItem(
        nama: 'Indomie Goreng Spesial (5 pcs)',
        qty: '1x @ Rp 16.200',
        hargaSatuan: 'Rp 16.200',
        total: 'Rp 16.200',
        hemat: 'Hemat Rp 3.300',
      ),
    ],
    this.totalBelanja = 'Rp 85.100',
    this.jumlahBarang = '4 Barang',
    this.diskonPromo = '-Rp 12.100',
    this.diskonVoucher = '-Rp 10.000',
    this.biayaLayanan = 'Rp 1.000',
    this.totalBayar = 'Rp 64.000',
    this.metodeBayar = 'BRI',
    this.metodeId = 'ID: 8892-0198-4421',
    this.poin = '+128 Poin',
    this.stempel = '+1 (8/10)',
    this.kodeBarcode = 'GM-8921-9825-0180-1224',
  });
  final String nomor;
  final String waktu;
  final String kasir;
  final String kurir;
  final List<StrukItem> items;
  final String totalBelanja;
  final String jumlahBarang;
  final String diskonPromo;
  final String diskonVoucher;
  final String biayaLayanan;
  final String totalBayar;
  final String metodeBayar;
  final String metodeId;
  final String poin;
  final String stempel;
  final String kodeBarcode;
}

/// Struk digital pesanan sesuai desain Figma.
class StrukPage extends StatelessWidget {
  const StrukPage({super.key, this.data = const StrukData()});
  final StrukData data;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: authBackground,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _CircleIcon(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                _CircleIcon(
                  icon: Icons.ios_share,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _summary(data)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ringkasan struk disalin'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            artwork(
                              'garden_symbol_auth',
                              width: 36,
                              height: 30,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'GARDENMART SUPERMARKET',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: gardenInk,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Cabang Diponegoro No. 42, Medan • Telp (061) 829-1122',
                              style: TextStyle(fontSize: 10, color: textGrey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _DashedLine(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Meta(
                              label: 'No. Transaksi',
                              value: data.nomor,
                            ),
                          ),
                          Expanded(
                            child: _Meta(
                              label: 'Waktu Transaksi',
                              value: data.waktu,
                              alignRight: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Meta(
                              label: 'Kasir / Picker',
                              value: data.kasir,
                            ),
                          ),
                          Expanded(
                            child: _Meta(
                              label: 'Kurir Toko',
                              value: data.kurir,
                              alignRight: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'RINCIAN BARANG BELANJA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textGrey,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in data.items) ...[
                        _ItemRow(item: item),
                        const SizedBox(height: 8),
                      ],
                      const _DashedLine(),
                      const SizedBox(height: 8),
                      _TotalRow(
                        label: 'Total Belanja (${data.jumlahBarang})',
                        value: data.totalBelanja,
                      ),
                      const SizedBox(height: 4),
                      _TotalRow(
                        label: 'Diskon Promo JSM',
                        value: data.diskonPromo,
                      ),
                      const SizedBox(height: 4),
                      _TotalRow(
                        label: 'Diskon Voucher Toko',
                        value: data.diskonVoucher,
                      ),
                      const SizedBox(height: 4),
                      const _TotalRow(
                        label: 'Ongkir Instan (15 mnt)',
                        value: 'GRATIS',
                        valueColor: Color(0xFF397A24),
                      ),
                      const SizedBox(height: 4),
                      _TotalRow(
                        label: 'Biaya Layanan',
                        value: data.biayaLayanan,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'TOTAL BAYAR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: gardenInk,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            data.totalBayar,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: gardenInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _DashedLine(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(fontSize: 11, color: textGrey),
                          ),
                          const Spacer(),
                          Text(
                            data.metodeId,
                            style: const TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF397A24),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data.metodeBayar,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: gardenInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _RewardPill(
                              icon: Icons.star,
                              text: 'Poin Didapat: ${data.poin}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RewardPill(
                              icon: Icons.check_circle_outline,
                              text: 'Stempel: ${data.stempel}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const _Barcode(),
                                const SizedBox(height: 4),
                                Text(
                                  data.kodeBarcode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: gardenInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          QrImageView(
                            data: data.kodeBarcode,
                            size: 64,
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Terima kasih telah berbelanja di GardenMart.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: textGrey),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Simpan struk digital ini sebagai bukti transaksi resmi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _downloadStruk(context, data),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto',
                  ),
                ),
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download struk'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: gardenInk),
      padding: EdgeInsets.zero,
    ),
  );
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      final count =
          (constraints.maxWidth / (dashWidth + dashSpace)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          count,
          (_) => const SizedBox(
            width: dashWidth,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFC9D6C0)),
            ),
          ),
        ),
      );
    },
  );
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.label,
    required this.value,
    this.alignRight = false,
  });
  final String label;
  final String value;
  final bool alignRight;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment:
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: textGrey),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: gardenInk,
        ),
      ),
    ],
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final StrukItem item;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nama,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  item.qty,
                  style: const TextStyle(fontSize: 11, color: textGrey),
                ),
                if (item.hemat != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F3D8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.hemat!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF397A24),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (item.hargaCoret != null)
            Text(
              item.hargaCoret!,
              style: const TextStyle(
                fontSize: 11,
                color: textGrey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            item.total,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: gardenInk,
            ),
          ),
        ],
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor = gardenInk,
  });
  final String label;
  final String value;
  final Color valueColor;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: textGrey),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
    ],
  );
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F3D8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF397A24)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF397A24),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Barcode batang hitam dengan lebar bervariasi (pola tetap).
class _Barcode extends StatelessWidget {
  const _Barcode();
  @override
  Widget build(BuildContext context) {
    const widths = [
      3.0, 1.0, 2.0, 1.0, 1.0, 3.0, 2.0, 1.0, 4.0, 1.0, 2.0, 2.0, 1.0,
      3.0, 1.0, 1.0, 2.0, 4.0, 1.0, 2.0, 1.0, 3.0, 1.0, 2.0, 2.0, 1.0,
      1.0, 3.0, 2.0, 1.0, 4.0, 1.0, 2.0, 1.0, 1.0, 3.0, 2.0, 2.0, 1.0,
    ];
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final w in widths)
            Container(width: w, color: gardenInk),
        ],
      ),
    );
  }
}

/// Ringkasan teks struk untuk dibagikan lewat clipboard.
String _summary(StrukData data) {
  final buffer = StringBuffer()
    ..writeln('GARDENMART SUPERMARKET')
    ..writeln('Struk ${data.nomor}')
    ..writeln(data.waktu)
    ..writeln('Kasir: ${data.kasir} • Kurir: ${data.kurir}');
  for (final item in data.items) {
    buffer.writeln('${item.nama} (${item.qty}) = ${item.total}');
  }
  buffer
    ..writeln('Total Belanja (${data.jumlahBarang}): ${data.totalBelanja}')
    ..writeln('Diskon Promo JSM: ${data.diskonPromo}')
    ..writeln('Diskon Voucher Toko: ${data.diskonVoucher}')
    ..writeln('Biaya Layanan: ${data.biayaLayanan}')
    ..writeln('Total Bayar: ${data.totalBayar} (${data.metodeBayar})');
  return buffer.toString();
}

/// Unduh struk sebagai file PDF ke direktori dokumen aplikasi, lalu
/// tampilkan nama filenya. Berbagi file ke aplikasi lain belum didukung
/// (butuh share_plus); file bisa dibuka dari file manager.
Future<void> _downloadStruk(BuildContext context, StrukData data) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Text(
          'GARDENMART SUPERMARKET',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Struk ${data.nomor}'),
        pw.Text(data.waktu),
        pw.Text('Kasir: ${data.kasir} • Kurir: ${data.kurir}'),
        pw.SizedBox(height: 12),
        for (final item in data.items)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text('${item.nama} (${item.qty})')),
              pw.Text(item.total),
            ],
          ),
        pw.Divider(),
        _pdfRow('Total Belanja (${data.jumlahBarang})', data.totalBelanja),
        _pdfRow('Diskon Promo JSM', data.diskonPromo),
        _pdfRow('Diskon Voucher Toko', data.diskonVoucher),
        _pdfRow('Biaya Layanan', data.biayaLayanan),
        pw.Divider(),
        _pdfRow('Total Bayar', data.totalBayar),
        pw.Text('Pembayaran: ${data.metodeBayar} ${data.metodeId}'),
        pw.Text('Poin Didapat: ${data.poin} • Stempel: ${data.stempel}'),
      ],
    ),
  );
  final dir = await getApplicationDocumentsDirectory();
  final name =
      'struk_${data.nomor.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf';
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(await doc.save());
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Struk tersimpan: $name')),
    );
  }
}

pw.Widget _pdfRow(String label, String value) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label), pw.Text(value)],
    );

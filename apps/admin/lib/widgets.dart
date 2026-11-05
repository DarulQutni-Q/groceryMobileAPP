import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const hijauTua = Color(0xFF1E3A1E);
const latar = Color(0xFFF4F7F0);

/// Warna lime khas GardenMart, dipakai hanya untuk ubin logo.
const hijauLime = Color(0xFF75BF26);

/// Lockup merek GardenMart: ubin lime berisi ikon toko, kata "GardenMart",
/// dan label kecil "Admin". Dipakai di header, drawer, dan kartu login
/// supaya ketiganya punya satu identitas yang sama.
class LogoGardenMart extends StatelessWidget {
  const LogoGardenMart({
    super.key,
    required this.gelap,
    this.ukuranJudul = 18,
    this.ukuranUbin = 36,
    this.denganTag = true,
  });

  /// true bila diletakkan di atas latar gelap (header/drawer): teks putih.
  /// false bila di atas latar terang (kartu login): teks hijau tua.
  final bool gelap;
  final double ukuranJudul;
  final double ukuranUbin;

  /// false di tempat sempit (AppBar HP, drawer) supaya lockup tidak meluber.
  final bool denganTag;

  @override
  Widget build(BuildContext context) {
    final warnaTeks = gelap ? Colors.white : hijauTua;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ukuranUbin,
          height: ukuranUbin,
          decoration: BoxDecoration(
            color: hijauLime,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.storefront,
            color: hijauTua,
            size: ukuranUbin * 0.6,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'GardenMart',
          style: TextStyle(
            fontSize: ukuranJudul,
            fontWeight: FontWeight.w600,
            color: warnaTeks,
          ),
        ),
        if (denganTag) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: warnaTeks.withAlpha(140)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: warnaTeks,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class KartuStat extends StatelessWidget {
  const KartuStat({
    super.key,
    required this.judul,
    required this.nilai,
    this.subjudul,
    this.lebar,
  });

  final String judul;
  final String nilai;
  final String? subjudul;
  final double? lebar;

  @override
  Widget build(BuildContext context) {
    final kartu = Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(
              nilai,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: hijauTua,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (subjudul != null) ...[
              const SizedBox(height: 4),
              Text(subjudul!, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ],
        ),
      ),
    );
    if (lebar == null) return kartu;
    return SizedBox(width: lebar, child: kartu);
  }
}

class BarisPaginasi extends StatelessWidget {
  const BarisPaginasi({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Total $total data'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Halaman sebelumnya',
              onPressed: page > 1 ? () => onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Halaman $page dari $totalPages'),
            IconButton(
              tooltip: 'Halaman berikutnya',
              onPressed: page < totalPages ? () => onPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

Future<bool> konfirmasi(
  BuildContext context,
  String judul,
  String isi,
) async {
  final jawab = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, lanjutkan'),
        ),
      ],
    ),
  );
  return jawab ?? false;
}

void pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
}

/// True kalau galat berarti sesi habis (401): pemanggil harus logout.
bool sesiHabis(Object error) {
  return error is DioException && error.response?.statusCode == 401;
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const hijauTua = Color(0xFF1E3A1E);
const hijauLime = Color(0xFF75BF26);
const latar = Color(0xFFF4F7F0);

class KartuStat extends StatelessWidget {
  const KartuStat({
    super.key,
    required this.judul,
    required this.nilai,
    this.subjudul,
  });

  final String judul;
  final String nilai;
  final String? subjudul;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                fontWeight: FontWeight.bold,
                color: hijauTua,
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
    return Row(
      children: [
        Text('Total $total data'),
        const Spacer(),
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

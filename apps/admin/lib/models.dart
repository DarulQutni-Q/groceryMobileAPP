// Format helper dashboard (tanpa package tambahan).

String rupiah(int nilai) {
  final negatif = nilai < 0;
  var sisa = nilai.abs().toString();
  final potong = <String>[];
  while (sisa.length > 3) {
    potong.insert(0, sisa.substring(sisa.length - 3));
    sisa = sisa.substring(0, sisa.length - 3);
  }
  potong.insert(0, sisa);
  return '${negatif ? '- ' : ''}Rp ${potong.join('.')}';
}

String tanggal(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final lokal = dt.toLocal();
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${dua(lokal.day)}/${dua(lokal.month)}/${lokal.year} '
      '${dua(lokal.hour)}:${dua(lokal.minute)}';
}

const Map<String, String> labelStatusPesanan = {
  'baru': 'Baru',
  'diproses': 'Diproses',
  'dikemas': 'Dikemas',
  'diantar': 'Diantar',
  'selesai': 'Selesai',
  'dibatalkan': 'Dibatalkan',
  'ditolak': 'Ditolak',
};

String labelStatus(String status) => labelStatusPesanan[status] ?? status;

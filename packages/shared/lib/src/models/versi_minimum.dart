/// Hasil cek versi minimum dari backend (endpoint /versi-minimum).
class CekVersi {
  const CekVersi({
    required this.aplikasi,
    required this.versiSaatIni,
    required this.versiMinimum,
    required this.wajibUpdate,
  });

  factory CekVersi.fromJson(Map<String, dynamic> json) => CekVersi(
    aplikasi: json['aplikasi'] as String? ?? '',
    versiSaatIni: json['versi_saat_ini'] as String? ?? '',
    versiMinimum: json['versi_minimum'] as String? ?? '0.0.0',
    wajibUpdate: json['wajib_update'] as bool? ?? false,
  );

  final String aplikasi;
  final String versiSaatIni;
  final String versiMinimum;
  final bool wajibUpdate;
}

/// Perbandingan semver di sisi klien (cerminan backend/services/versi.py).
/// Sufiks build ("+1") diabaikan, komponen hilang = 0, versi tak valid
/// menghasilkan false (fail-open: aplikasi tetap jalan).
bool perluUpdate(String versiSaatIni, String versiMinimum) {
  final saatIni = _parse(versiSaatIni);
  final minimum = _parse(versiMinimum);
  if (saatIni == null || minimum == null) return false;
  for (var i = 0; i < 3; i++) {
    if (saatIni[i] != minimum[i]) return saatIni[i] < minimum[i];
  }
  return false;
}

List<int>? _parse(String versi) {
  final inti = versi.trim().split('+').first;
  if (inti.isEmpty) return null;
  final bagian = inti.split('.');
  if (bagian.length > 3) return null;
  final angka = <int>[];
  for (final b in bagian) {
    final n = int.tryParse(b);
    if (n == null || n < 0) return null;
    angka.add(n);
  }
  while (angka.length < 3) {
    angka.add(0);
  }
  return angka;
}

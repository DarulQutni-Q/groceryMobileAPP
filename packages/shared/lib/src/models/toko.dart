class Toko {
  const Toko({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.kategori,
    required this.radiusKm,
    required this.status,
    required this.metodeKirim,
    this.logoUrl,
    this.deskripsi,
    this.rekeningBank,
    this.jamBuka,
    this.jamTutup,
  });

  final String id, nama, alamat, telepon, status;
  final String? logoUrl, deskripsi, rekeningBank;
  final String? jamBuka, jamTutup;
  final List<String> kategori, metodeKirim;
  final int radiusKm;

  factory Toko.fromJson(Map<String, dynamic> json) => Toko(
    id: json['id'] as String,
    nama: json['nama'] as String,
    alamat: json['alamat'] as String,
    telepon: json['telepon'] as String,
    logoUrl: json['logo_url'] as String?,
    deskripsi: json['deskripsi'] as String?,
    rekeningBank: json['rekening_bank'] as String?,
    jamBuka: json['jam_buka'] as String?,
    jamTutup: json['jam_tutup'] as String?,
    kategori: List<String>.from(json['kategori'] as List),
    radiusKm: json['radius_km'] as int,
    status: json['status'] as String,
    metodeKirim: List<String>.from(json['metode_kirim'] as List),
  );
}

class JamBuka {
  const JamBuka({
    required this.hari,
    required this.isTutup,
    this.jamBuka,
    this.jamTutup,
  });
  final String hari;
  final bool isTutup;
  final String? jamBuka, jamTutup;

  factory JamBuka.fromJson(Map<String, dynamic> json) => JamBuka(
    hari: json['hari'] as String,
    isTutup: json['is_tutup'] as bool,
    jamBuka: json['jam_buka'] as String?,
    jamTutup: json['jam_tutup'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'hari': hari,
    'is_tutup': isTutup,
    'jam_buka': jamBuka,
    'jam_tutup': jamTutup,
  };
}

class Alamat {
  const Alamat({
    required this.id,
    required this.label,
    required this.namaPenerima,
    required this.noHp,
    required this.alamatLengkap,
    this.patokan,
    required this.isUtama,
    this.latitude,
    this.longitude,
  });
  final String id, label, namaPenerima, noHp, alamatLengkap;
  final String? patokan;
  final bool isUtama;

  /// Titik GPS dari backend (nullable: alamat lama belum tentu punya).
  /// Backend mewajibkan keduanya diisi bersama, jadi keduanya null atau
  /// keduanya terisi.
  final double? latitude;
  final double? longitude;
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'nama_penerima': namaPenerima,
    'no_hp': noHp, 'alamat_lengkap': alamatLengkap, 'patokan': patokan, 'is_utama': isUtama,
    'latitude': latitude, 'longitude': longitude};

  factory Alamat.fromJson(Map<String, dynamic> json) => Alamat(
    id: json['id'] as String,
    label: json['label'] as String,
    namaPenerima: json['nama_penerima'] as String,
    noHp: json['no_hp'] as String,
    alamatLengkap: json['alamat_lengkap'] as String,
    patokan: json['patokan'] as String?,
    isUtama: json['is_utama'] as bool,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

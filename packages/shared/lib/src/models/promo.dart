class Promo {
  const Promo({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.labelTombol,
    required this.isDemo,
  });
  final String id, judul, deskripsi, labelTombol;
  final bool isDemo;

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
    id: json['id'] as String,
    judul: json['judul'] as String,
    deskripsi: json['deskripsi'] as String,
    labelTombol: json['label_tombol'] as String,
    isDemo: json['is_demo'] as bool,
  );
}

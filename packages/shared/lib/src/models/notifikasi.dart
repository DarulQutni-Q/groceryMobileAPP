class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.judul,
    required this.isi,
    this.pesananId,
    required this.dibaca,
    required this.createdAt,
  });
  final String id, judul, isi;
  final String? pesananId;
  final bool dibaca;
  final DateTime createdAt;

  factory Notifikasi.fromJson(Map<String, dynamic> json) => Notifikasi(
        id: json['id'] as String,
        judul: json['judul'] as String,
        isi: json['isi'] as String,
        pesananId: json['pesanan_id'] as String?,
        dibaca: json['dibaca'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class NotifikasiList {
  const NotifikasiList({required this.data, required this.belumDibaca});
  final List<Notifikasi> data;
  final int belumDibaca;

  factory NotifikasiList.fromJson(Map<String, dynamic> json) => NotifikasiList(
        data: (json['data'] as List<dynamic>)
            .map((item) => Notifikasi.fromJson(item as Map<String, dynamic>))
            .toList(),
        belumDibaca: json['belum_dibaca'] as int,
      );
}

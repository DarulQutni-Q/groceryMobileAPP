class RiwayatStatus {
  const RiwayatStatus({
    required this.id,
    required this.pesananId,
    required this.status,
    required this.createdAt,
    this.keterangan,
  });

  factory RiwayatStatus.fromJson(Map<String, dynamic> json) => RiwayatStatus(
    id: json['id'] as String,
    pesananId: json['pesanan_id'] as String,
    status: json['status'] as String,
    keterangan: json['keterangan'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id, pesananId, status;
  final String? keterangan;
  final DateTime createdAt;
}

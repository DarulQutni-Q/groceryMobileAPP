class ChatPesan {
  const ChatPesan({
    required this.id,
    required this.pesananId,
    required this.pengirimId,
    required this.pengirimPeran,
    required this.isi,
    required this.createdAt,
  });

  factory ChatPesan.fromJson(Map<String, dynamic> json) => ChatPesan(
    id: json['id'] as String,
    pesananId: json['pesanan_id'] as String,
    pengirimId: json['pengirim_id'] as String,
    pengirimPeran: json['pengirim_peran'] as String,
    isi: json['isi'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id, pesananId, pengirimId, pengirimPeran, isi;
  final DateTime createdAt;

  bool get dariToko => pengirimPeran == 'toko';
}

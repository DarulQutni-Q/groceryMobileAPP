import 'pesanan.dart';

class Pembayaran {
  const Pembayaran({
    required this.id,
    required this.pesananId,
    required this.metode,
    required this.status,
    required this.jumlah,
    this.paymentUrl,
    this.perluRekonsiliasi = false,
  });
  final String id, pesananId, metode, status;
  final int jumlah;
  final String? paymentUrl;
  final bool perluRekonsiliasi;

  factory Pembayaran.fromJson(Map<String, dynamic> json) => Pembayaran(
    id: json['id'] as String,
    pesananId: json['pesanan_id'] as String,
    metode: json['metode'] as String,
    status: json['status'] as String,
    jumlah: json['jumlah'] as int,
    paymentUrl: json['payment_url'] as String?,
    perluRekonsiliasi: json['perlu_rekonsiliasi'] as bool? ?? false,
  );
}

class HasilCheckout {
  const HasilCheckout(this.pesanan, this.pembayaran);
  final Pesanan pesanan;
  final Pembayaran pembayaran;
  factory HasilCheckout.fromJson(Map<String, dynamic> json) => HasilCheckout(
    Pesanan.fromJson(json['pesanan'] as Map<String, dynamic>),
    Pembayaran.fromJson(json['pembayaran'] as Map<String, dynamic>),
  );
}

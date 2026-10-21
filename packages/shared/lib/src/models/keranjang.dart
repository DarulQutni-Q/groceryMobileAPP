import 'produk.dart';

class KeranjangItem {
  const KeranjangItem({
    required this.produk,
    required this.qty,
    this.dipilih = true,
  });
  final Produk produk;
  final int qty;
  final bool dipilih;

  KeranjangItem copyWith({Produk? produk, int? qty, bool? dipilih}) =>
      KeranjangItem(
        produk: produk ?? this.produk,
        qty: qty ?? this.qty,
        dipilih: dipilih ?? this.dipilih,
      );
  Map<String, dynamic> toJson() => {
    'produk': produk.toJson(),
    'qty': qty,
    'dipilih': dipilih,
  };
  factory KeranjangItem.fromJson(Map<String, dynamic> json) => KeranjangItem(
    produk: Produk.fromJson(json['produk'] as Map<String, dynamic>),
    qty: json['qty'] as int,
    dipilih: json['dipilih'] as bool,
  );
}

class Keranjang {
  Keranjang({
    List<KeranjangItem> items = const [],
    this.memuat = false,
    this.pesan,
  }) : items = List.unmodifiable(items);
  final List<KeranjangItem> items;
  final bool memuat;
  final String? pesan;
  int get totalItem => items.fold(0, (n, item) => n + item.qty);
  int get jumlahDipilih =>
      items.where((item) => item.dipilih).fold(0, (n, item) => n + item.qty);
  int get subtotal => items
      .where((item) => item.dipilih)
      .fold(0, (n, item) => n + item.qty * item.produk.harga);
  bool get semuaDipilih =>
      items.isNotEmpty && items.every((item) => item.dipilih);
  String? get tokoId => items.firstOrNull?.produk.tokoId;
}

class PesananItem {
  const PesananItem({
    this.produkId,
    required this.namaSnapshot,
    required this.hargaSnapshot,
    required this.qty,
  });
  final String? produkId;
  final String namaSnapshot;
  final int hargaSnapshot, qty;

  factory PesananItem.fromJson(Map<String, dynamic> json) => PesananItem(
    produkId: json['produk_id'] as String?,
    namaSnapshot: json['nama_snapshot'] as String,
    hargaSnapshot: json['harga_snapshot'] as int,
    qty: json['qty'] as int,
  );
}

class Pesanan {
  const Pesanan({
    required this.id,
    required this.kode,
    required this.status,
    required this.alamatKirim,
    required this.metodeKirim,
    required this.slotWaktu,
    required this.subtotal,
    required this.diskon,
    required this.ongkir,
    required this.biayaLayanan,
    required this.total,
    required this.items,
    required this.createdAt,
    this.catatan,
    this.tolakAlasan,
    this.namaPembeli,
    this.teleponPembeli,
    this.serverTime,
    this.undoUntil,
  });
  final String id, kode, status, alamatKirim, metodeKirim, slotWaktu;
  final String? catatan, tolakAlasan, namaPembeli, teleponPembeli;
  final int subtotal, diskon, ongkir, biayaLayanan, total;
  final List<PesananItem> items;
  final DateTime createdAt;
  final DateTime? serverTime, undoUntil;

  factory Pesanan.fromJson(Map<String, dynamic> json) => Pesanan(
    id: json['id'] as String,
    kode: json['kode'] as String,
    status: json['status'] as String,
    alamatKirim: json['alamat_kirim'] as String,
    metodeKirim: json['metode_kirim'] as String,
    slotWaktu: json['slot_waktu'] as String,
    catatan: json['catatan'] as String?,
    tolakAlasan: json['tolak_alasan'] as String?,
    namaPembeli: json['nama_pembeli'] as String?,
    teleponPembeli: json['telepon_pembeli'] as String?,
    subtotal: json['subtotal'] as int,
    diskon: json['diskon'] as int,
    ongkir: json['ongkir'] as int,
    biayaLayanan: json['biaya_layanan'] as int,
    total: json['total'] as int,
    items: (json['items'] as List)
        .map((item) => PesananItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
    serverTime: json['server_time'] == null
        ? null
        : DateTime.parse(json['server_time'] as String),
    undoUntil: json['undo_until'] == null
        ? null
        : DateTime.parse(json['undo_until'] as String),
  );
}

// PLACEHOLDER - BUKAN DATA ASLI, BUKAN HARGA/DISKON DARI SELLER.
//
// Satu-satunya sumber data diskon di layar keranjang, sengaja dipusatkan
// di file ini supaya pergantian ke data asli hanya menyentuh satu tempat.
//
// TODO: hapus file ini dan ganti pemakaiannya dengan field asli dari
// seller/backend (original_price dan discount_percent pada produk) begitu
// aplikasi seller terhubung dan data produk asli mengalir. Nilai di bawah
// ini HANYA angka contoh untuk memverifikasi tampilan (badge, harga coret,
// banner hemat); jangan pernah disajikan sebagai harga atau diskon nyata.
//
// Produk yang tidak ada di map ini tidak menampilkan badge/harga coret,
// karena tidak ada diskon placeholder untuknya.
import 'package:grocery_shared/shared.dart';

/// Diskon placeholder untuk satu produk: harga asli contoh.
class PlaceholderDiskon {
  const PlaceholderDiskon({required this.hargaAsli});
  final int hargaAsli;

  /// Persen diskon dibulatkan, dihitung dari harga asli placeholder.
  int persenDiskon(int harga) {
    if (hargaAsli <= harga) return 0;
    return ((hargaAsli - harga) * 100 / hargaAsli).round();
  }

  /// Hemat per item, dihitung dari harga asli placeholder.
  int hematPerItem(int harga) => hargaAsli <= harga ? 0 : hargaAsli - harga;
}

/// Placeholder per id produk. Satu map ini saja; jangan sebar literal
/// harga asli/diskon di widget lain.
const Map<String, PlaceholderDiskon> placeholderDiskonPerProduk = {
  // Harga jual 33900, harga asli placeholder 39500 -> -14%.
  'p3': PlaceholderDiskon(hargaAsli: 39500),
  // Harga jual 17500, harga asli placeholder 20000 -> -13%.
  'p1': PlaceholderDiskon(hargaAsli: 20000),
  // Harga jual 16200, harga asli placeholder 18000 -> -10%.
  'p2': PlaceholderDiskon(hargaAsli: 18000),
};

PlaceholderDiskon? placeholderDiskonUntuk(Produk produk) =>
    placeholderDiskonPerProduk[produk.id];

/// Total hemat dari item yang dipilih saja, konsisten dengan subtotal
/// (yang juga hanya menghitung item terpilih). Dipakai banner hemat dan
/// baris Diskon di Rincian Biaya, jadi keduanya selalu sama.
int totalHematPlaceholder(Iterable<KeranjangItem> items) =>
    items.where((item) => item.dipilih).fold(0, (total, item) {
      final diskon = placeholderDiskonUntuk(item.produk);
      if (diskon == null) return total;
      return total + diskon.hematPerItem(item.produk.harga) * item.qty;
    });

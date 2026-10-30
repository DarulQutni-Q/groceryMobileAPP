// PLACEHOLDER - BUKAN DATA ASLI, BUKAN DOMPET/KARTU PENGGUNA YANG NYATA.
//
// Satu-satunya sumber data dompet dan kartu di layar Metode Pembayaran,
// sengaja dipusatkan di file ini supaya pergantian ke data asli hanya
// menyentuh satu tempat.
//
// TODO: hapus file ini dan ganti pemakaiannya dengan data asli dari
// provider begitu integrasi tersedia: koneksi dompet (OAuth GoPay/
// ShopeePay + API saldo) dan vault kartu (tokenisasi: PAN tersamar +
// expiry + network dari kartu yang disimpan). Nilai di bawah ini HANYA
// data contoh dari referensi Figma untuk memverifikasi tampilan; jangan
// pernah disajikan sebagai saldo, kartu, atau status hubung pengguna yang
// nyata.
//
// Aplikasi TIDAK punya koneksi dompet atau bank: tombol Top Up dan
// Hubungkan menampilkan dialog jujur, tidak pernah mengubah saldo atau
// status hubung. Badge "Utama" di bawah adalah lencana dari data contoh,
// BUKAN status radio: radio menandai metode yang dipilih pengguna,
// lencana menandai kartu utama dari data contoh.

/// Dompet digital contoh: nama, teks status, dan tombol aksinya.
class PlaceholderDompet {
  const PlaceholderDompet({
    required this.nama,
    required this.status,
    required this.terhubung,
    required this.tombol,
  });
  final String nama;
  final String status;
  final bool terhubung;
  final String tombol;
}

/// Kartu contoh: judul, nomor tersamar, network, lencana utama, dan kode
/// metode checkout yang dipetakan dari kartu ini.
class PlaceholderKartu {
  const PlaceholderKartu({
    required this.judul,
    required this.tersamar,
    required this.network,
    required this.utama,
    required this.metodeBayar,
  });
  final String judul;
  final String tersamar;
  final String network;
  final bool utama;
  final String metodeBayar;
}

/// Dompet contoh, urutan sama dengan tampilannya di layar.
const placeholderDompet = [
  PlaceholderDompet(
    nama: 'Saldo GoPay',
    status: 'Rp 445.200',
    terhubung: true,
    tombol: 'Top Up',
  ),
  PlaceholderDompet(
    nama: 'ShopeePay',
    status: 'Belum Terhubung',
    terhubung: false,
    tombol: 'Hubungkan',
  ),
];

/// Kartu contoh, urutan sama dengan tampilannya di layar dan dengan indeks
/// radio di halaman (0 = BCA, 1 = Mandiri).
const placeholderKartu = [
  PlaceholderKartu(
    judul: 'BCA Mastercard Debit',
    tersamar: '•••• 4122 • Exp 08/28',
    network: 'mastercard',
    utama: true,
    metodeBayar: 'va_bca',
  ),
  PlaceholderKartu(
    judul: 'Mandiri Visa Debit',
    tersamar: '•••• 8921 • Exp 11/27',
    network: 'visa',
    utama: false,
    metodeBayar: 'va_mandiri',
  ),
];

/// Kode metode checkout untuk indeks radio terpilih. Null kalau tidak ada
/// kartu yang dipilih (indeks -1), supaya tidak ada preferensi yang
/// ditulis saat pengguna menyimpan tanpa memilih.
String? metodeBayarDariKartu(int index) {
  if (index < 0 || index >= placeholderKartu.length) return null;
  return placeholderKartu[index].metodeBayar;
}

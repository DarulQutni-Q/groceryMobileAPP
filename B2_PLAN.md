# B2: katalog dan keranjang customer

Sumber: attachment B2, prd.md bagian3.2-3.4, design.md bagian3/4 dan rules.md.
Roadmap bertahap dan 01-main-cluster.png tidak tersedia. Acuan aktual:
Pasted image(5)/(6) untuk Home dan (8) untuk Keranjang. Detail produk tidak
memiliki gambar khusus. Semua acuan sudah diperiksa langsung.

## Arah visual dan batas

Lima tab tetap Beranda/Promo/Scan QR/Pesanan/Akun. Ikon tas kanan atas membuka
Keranjang dengan badge jumlah. Home #EFF4EB, promo #96E23B, tombol #192D1E;
keranjang #E8F1E2, total #9FDD56, tombol #142618. Gunakan Material3 yang sudah
tersedia: Card, InkWell, FilledButton, IconButton, Checkbox, NavigationBar,
SearchBar/TextField, Badge, AlertDialog dan ModalBottomSheet.

Isi yang dihitung mengikuti API/state, bukan angka contoh yang tidak konsisten
pada screenshot. Tidak mengerjakan checkout, pembayaran, voucher, poin atau
pelacakan sungguhan. cached_network_image wajib untuk foto produk. Search500ms,
pagination, countdown menuju23:59 lokal dan state gagal/loading/empty diuji.

## Pohon keputusan dan ADR

1. Backend katalog:
   - GET /produk dan detail menambahkan pembacaan customer. Cabang seller,
     response array lama dan seluruh dependency mutasi tetap dipertahankan.
   - Customer hanya melihat toko buka dan produk tersedia; stok0 tetap tampil
     sebagai Habis dan tidak dapat dimasukkan ke keranjang.
   - Customer memakai envelope data/meta secara default1/20, maksimal100.
   - GET /toko dan /toko/{id} memakai schema publik. Jangan mengekspos owner_id
     atau rekening_bank. Jam hari ini mengikuti WIB dan query dibatasi tetap.
   - GET /kategori memakai DISTINCT katalog yang terlihat. /promo berupa data
     demo B2 yang ditandai is_demo; bukan bukti diskon suatu produk.
2. Shared: tambah metode katalog berhalaman tanpa mengubah ProdukApi.list seller.
   Toko yang sudah ada ditambah metadata jam opsional; data seller tetap utuh.
   Keranjang per akun disimpan lokal, tanpa endpoint cart/checkout.
3. Keranjang: pertanyaan satu toko atau banyak toko telah dikirim. Asumsi kerja
   satu toko, dengan konfirmasi sebelum mengganti isi, sudah disampaikan.
   Jawaban pengguna masih terbuka dan dapat mengubah pilihan ini.
4. Harga coret/deskripsi belum ada pada model produk. Pertanyaan cakupan telah
   dikirim: rekomendasi gunakan data asli dan sembunyikan diskon tanpa sumber;
   pilihan lain menambah kolom backend sekarang. Asumsi kerja sudah disampaikan:
   gunakan harga asli, tanpa diskon buatan; jawaban pengguna masih terbuka.

## Dampak dan seam

- get_authenticated_user -> GET produk/katalog. get_current_user/get_store dan
  get_produk terkunci untuk mutasi seller tidak dilonggarkan.
- ProdukApi.list -> Seller StoreNotifier dan tes store_api harus tetap kompatibel.
  Customer menambahkan metode list berhalaman, kategori, toko dan promo.
- Shared KeranjangNotifier -> customer shell, detail, cart dan badge. Simpan per
  user agar keranjang akun berbeda tidak tercampur; hindari hasil restore lama.
- CustomerApp.builder saat ini mengganti Navigator dengan Home placeholder.
  Shell customer membutuhkan Navigator untuk detail/cart, terpisah per sesi.
- Tidak mengedit apps/seller atau perubahan pengguna yang sudah ada pada A3/root.
  Snapshot patch pengguna ada di /tmp/b2-preserved-user.patch untuk perbandingan.

## Urutan kerja dan commit

1. Tes HTTP katalog merah, lalu layanan/schema/endpoint minimum; verifikasi
   auth, filter, pagination, query count, privasi dan kompatibilitas seller.
2. Shared API/model dan seam tests. Dengan asumsi keranjang di atas,
   bangun state+persistensi cart dengan tes stok, pilihan, qty dan isolasi akun.
3. Provider katalog: debounce, kategori, pagination, race, retry. Layar Home
   mengikuti acuan, detail produk dan keranjang yang menghitung data nyata.
4. Tes widget dan perjalanan Android: browse/search/filter/detail/add/cart/qty/
   select/delete/restore/countdown. Screenshot Home, detail, cartisi dan kosong.
5. Regresi backend/shared/customer/seller, build/install/run dan review read-only.
   Tulis curl, tabel hasil, handoff dan gap. Commit kecil setelah tiap bagian lulus.

Kontrak tes B1 GET /produk=403 berubah secara eksplisit pada B2 menjadi akses
katalog200. Perbarui tes kontrak itu dengan tes baca baru yang gagal dahulu;
pertahankan403 pada semua mutasi seller, pesanan dan laporan. Jangan menghapus
assertion keamanan lain untuk meluluskan implementasi.

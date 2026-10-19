# Rancangan Fase A2

Status: draft. Pesan A2 terpotong pada "Varian tutup: kalau stat". Belum ada kode fitur atau migrasi A2 yang diterapkan.

## Sumber yang sudah dibaca

- Permintaan A2 pada task ini: seller dan backend saja; customer tidak disentuh. Toko, JamBuka, Produk, upload lokal maksimal 5 MB, lima tab, statistik nol sebelum ada pesanan, stok menipis jika `stok <= 5`.
- `prd.md` bagian 2.2-2.7 dan `design.md` bagian 3-4. Dokumen aktual berada di root, bukan `docs/`.
- `rules.md`, `AGENTS.md`, `CONTEXT.md`, dan implementasi A1 yang ada.
- `docs/ROADMAP_BERTAHAP.md` belum ada. Detail fase mengikuti permintaan A2, bukan asumsi dari plan lama.

## Acuan UI aktual

Nama canonical pada PRD berbeda dari file gambar yang tersedia.

| Layar | File di `docs/screenshots/seller/` |
| --- | --- |
| Beranda buka, tutup, offline | `Pasted image (4).png`, `(5).png`, `(6).png` |
| Produk, toggle, hasil pencarian kosong, toko kosong | `Pasted image (7).png`, `(9).png`, `(21).png`, `(22).png` |
| Tambah Produk | `Pasted image (8).png` |
| Toko, Info Toko, Jam Buka | `Pasted image (12).png`, `(13).png`, `(14).png` |

Gunakan widget Material 3 yang disesuaikan dengan gambar. Token sampel: latar `#FDFFF4`, tombol `#7EA895`, navigasi `#7AA491`, kartu statistik `#ECE5D0`, `#B3CEDD`, `#FCE9E7`, `#F8DA7A`. Area aplikasi pada raster utama sekitar x=35-437 dan y=34-908; bingkai perangkat tidak dirender. Tidak ada URL/node Figma atau font sumber pada dokumen yang tersedia.

## Pohon keputusan dan rekomendasi

1. **Cakupan:** backend toko/produk, shared API/model, Beranda/Produk/Toko. Laporan/Pesanan placeholder. Detail UI dan acceptance yang terpotong masih menunggu kelanjutan pesan.
2. **Siklus hidup toko:** rekomendasi satu toko per seller, `owner_id` unik. Migrasi membuat toko untuk seller A1 dari `nama_toko`; registrasi baru membuat User dan Toko dalam satu transaksi. Untuk seller Google tanpa nama toko, perlu menetapkan fallback dan data profil awal. Jangan mengarang kategori/pengiriman lama karena A1 tidak menyimpannya.
3. **Kepemilikan:** seluruh query memakai seller dari JWT. Akses produk milik seller lain menghasilkan 404. `owner_id`/`toko_id` tidak diterima dari payload seller.
4. **Form produk:** screenshot memakai harga textfield dan stok stepper, sedangkan PRD menyebut stepper harga. Rekomendasi ikuti screenshot. Backend mewajibkan kategori, tetapi screenshot tidak menampilkan inputnya; rekomendasi menambahkan pilihan kategori yang jelas, menunggu kesepakatan.
5. **Beranda:** Penjualan/Pesanan/Produk Terjual nol pada A2; Stok Menipis dan Perlu Tindakan berasal dari produk toko sendiri. Banner "3 Pesan baru menunggu" mengikuti placeholder yang diminta, bukan jumlah pesanan nyata. Varian tutup pada screenshot hanya dua statistik; kelanjutan pesan diperlukan untuk menentukan perilakunya.
6. **Jam buka:** tepat tujuh hari unik. Validasi jam hanya pada hari aktif; format/jam awal toko lama menunggu cakupan lengkap. Jadwal belum otomatis mengubah status toko kecuali diminta.
7. **Upload:** multipart, JPEG/PNG/WebP terverifikasi isi, batas 5 MB saat membaca, nama file UUID. Jangan memakai nama file klien sebagai path. File baru dibersihkan jika penyimpanan database gagal. Volume upload persisten dan writable oleh user non-root container; `foto_url` harus dapat dijangkau perangkat.
8. **Sesi seller:** state toko/produk dibersihkan saat logout/pergantian akun. Hasil request dari akun lama tidak boleh masuk ke state akun baru.

Butir di atas adalah rekomendasi, belum keputusan yang disetujui. Skill `grill-me` yang sudah dibaca mensyaratkan: "Do not act on the plan until the user confirms shared understanding."

## Dampak dan seam tes

| Area | Entry point/konsumen | Verifikasi |
| --- | --- | --- |
| Model/migrasi | Alembic dan metadata SQLAlchemy | Upgrade database A1 berisi akun email/Google; constraint owner/hari; akun lama tetap dapat login |
| Auth dan pembuatan toko | Register/email/Google service | User+Toko atomik, sinkron nama toko ke respons auth A1 |
| Router toko/produk | `app.main:create_app`, JWT dependency | HTTP seller A/B, CRUD/search/filter/toggle, akses silang ditolak |
| Validasi/CORS | Handler 422 dan middleware | Pesan harga/stok/satuan/jam Indonesia, preflight PUT |
| Upload dan container | Router foto, static serving, volume | Gambar valid/palsu, tepat/melebihi batas, path traversal, rollback, file bertahan setelah recreate container |
| Shared model/API | Provider seller | Serialisasi, bearer/refresh yang sudah ada, multipart, error Indonesia |
| Shell dan layar | AuthFlow authenticated | Lima tab, CRUD/toggle nyata, statistik konsisten, state akun terisolasi |
| UI | M3, screenshot sumber | Viewport HP kecil/keyboard, offline/retry/empty/loading, screenshot tiap layar dan varian |

## Urutan setelah cakupan lengkap disepakati

1. Tes HTTP toko gagal lebih dulu, lalu model/migrasi/profil/jam/status. Uji migrasi PostgreSQL nyata secara terpisah dari SQLite fixture.
2. Tes ownership dan validasi produk, lalu CRUD/search/filter/toggle.
3. Tes multipart dan persistensi file, lalu upload lokal beserta volume Docker.
4. Model/API shared dan tes seam; provider seller dengan isolasi sesi.
5. Shell lima tab dan satu alur lengkap tambah produk -> daftar -> toggle -> statistik, lalu profil/jam toko.
6. Curl acceptance, seluruh tes A1+A2, analyzer/lint/build/import/Compose, run Android dan bukti screenshot. Review independen sebelum commit/push kecil berikutnya.

## Yang masih dibutuhkan

- Kelanjutan prompt mulai "Varian tutup: kalau stat", termasuk detail Produk, Tambah Produk, Toko dan tes/deliverable A2.
- Kesepakatan pembuatan/default toko akun lama dan fallback nama toko Google.
- Penyelesaian perbedaan stepper/kategori pada form dan jumlah statistik varian tutup.

Customer, transaksi pesanan, pembayaran, laporan nyata, S3, dan perubahan auth di luar integrasi toko tidak ditambahkan pada fase ini.

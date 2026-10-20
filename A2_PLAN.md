# Rancangan Fase A2

Status: disetujui pengguna untuk dikerjakan lengkap sebelum A3. Detail pesan yang terpotong dilengkapi dari PRD dan screenshot yang tersedia. Implementasi dimulai dengan tes HTTP.

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

1. **Cakupan:** backend toko/produk, shared API/model, Beranda/Produk/Toko. Laporan/Pesanan placeholder. Detail pesan yang terpotong dilengkapi dari PRD/screenshot sesuai persetujuan pengguna.
2. **Siklus hidup toko:** satu toko per seller, `owner_id` unik. Migrasi membuat toko untuk seller A1 dari `nama_toko`; registrasi baru membuat User dan Toko dalam satu transaksi. Seller Google memakai fallback `Toko [nama pemilik]`, dibatasi 120 karakter. Data kategori/pengiriman lama tidak dikarang karena A1 tidak menyimpannya.
3. **Kepemilikan:** seluruh query memakai seller dari JWT. Akses produk milik seller lain menghasilkan 404. `owner_id`/`toko_id` tidak diterima dari payload seller.
4. **Form produk:** harga textfield dan stok stepper mengikuti screenshot. Field kategori ditambahkan karena wajib pada kontrak API; keputusan ini sudah disetujui.
5. **Beranda:** Penjualan/Pesanan/Produk Terjual nol pada A2; Stok Menipis dan Perlu Tindakan berasal dari produk toko sendiri. Banner "3 Pesan baru menunggu" adalah placeholder yang diminta. Varian tutup tetap empat statistik sesuai kontrak A2 dan menambahkan banner tutup.
6. **Jam buka:** tepat tujuh hari unik. Hari aktif memerlukan jam lokal tanpa offset dan buka sebelum tutup. Toko baru/hasil migrasi mengawali tujuh hari tutup. Jadwal tidak otomatis mengubah status toko.
7. **Upload:** multipart, JPEG/PNG/WebP terverifikasi isi, batas 5 MB saat membaca, nama file UUID. Jangan memakai nama file klien sebagai path. File baru dibersihkan jika penyimpanan database gagal. Volume upload persisten dan writable oleh user non-root container; `foto_url` harus dapat dijangkau perangkat.
8. **Sesi seller:** state toko/produk dibersihkan saat logout/pergantian akun. Hasil request dari akun lama tidak boleh masuk ke state akun baru.

Keputusan disetujui melalui pesan "yes, kerjakan ... kerjakan yg A2 dulu baru nanti A3". Satu toko otomatis per seller; fallback nama Google `Toko [nama pemilik]`; profil yang belum ada kosong; status awal tutup; tujuh hari awal tutup sampai jadwal disimpan. Stepper untuk stok dan input kategori tambahan disetujui. Beranda tetap empat statistik sesuai kontrak A2, dengan banner tutup dari PRD. A3 belum dikerjakan.

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

## Urutan pelaksanaan

1. Tes HTTP toko gagal lebih dulu, lalu model/migrasi/profil/jam/status. Uji migrasi PostgreSQL nyata secara terpisah dari SQLite fixture.
2. Tes ownership dan validasi produk, lalu CRUD/search/filter/toggle.
3. Tes multipart dan persistensi file, lalu upload lokal beserta volume Docker.
4. Model/API shared dan tes seam; provider seller dengan isolasi sesi.
5. Shell lima tab dan satu alur lengkap tambah produk -> daftar -> toggle -> statistik, lalu profil/jam toko.
6. Curl acceptance, seluruh tes A1+A2, analyzer/lint/build/import/Compose, run Android dan bukti screenshot. Review independen sebelum commit/push kecil berikutnya.

## Catatan keputusan A2

- Data kategori/pengiriman A1 yang hanya lokal tidak dapat dipulihkan setelah proses berakhir. Toko mengawali daftar kosong dan dapat dilengkapi lewat menu Toko.
- Foto produk wajib dipilih di UI sebelum simpan; backend tetap menerima produk tanpa foto karena upload terjadi sesudah create. UI menyimpan ID hasil create agar retry upload tidak menggandakan produk.
- Status toko manual, tidak otomatis mengikuti jam buka. Penjualan/Pesanan/Produk Terjual nol karena model Pesanan menunggu A3.
- Logo toko belum memiliki endpoint upload dalam kontrak A2. UI menampilkan logo/default; aksi ubah logo menjelaskan keterbatasan ini. Semua field profil lain, pengiriman, rekening dan jam disimpan ke backend.

Customer, transaksi pesanan, pembayaran, laporan nyata, S3, dan perubahan auth di luar integrasi toko tidak ditambahkan pada fase ini.

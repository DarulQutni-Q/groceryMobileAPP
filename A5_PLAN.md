# Rencana Fase A5

Sumber: permintaan A5, `prd.md` bagian 4, `design.md` bagian 4 dan 6,
`rules.md`, serta kode dan tes backend saat ini. Dokumen spesifikasi berada
di root; `docs/ROADMAP_BERTAHAP.md` tidak ditemukan. Tidak membuat fitur pembayaran.

## Keputusan kontrak dan batas cakupan

1. Flutter membaca produk dan pesanan sebagai array. Asumsi kompatibilitas: request lama
   tanpa page/per_page tetap array lengkap; request dengan salah satu parameter
   menerima data/meta, default page=1/per_page=20, per_page di atas 100 dibatasi 100.
2. Chip status di menu Toko tidak memiliki callback. Perbaikan membutuhkan
   pengecualian Flutter yang terbatas pada tombol dan tesnya. Tanpa persetujuan,
   diagnosis dilaporkan dan apps/ tidak diubah.

## Pohon perubahan dan dampak

| Jalur | Perubahan minimum | Konsumen dan pengaman |
| --- | --- | --- |
| Observabilitas | Request JSON, ID, waktu, user, traceback stderr, penanganan DB gagal | Semua route, termasuk error; log tidak memuat body/query/header rahasia |
| Pembatasan | Login 5/IP, register 3/IP, mutasi 60/user, Retry-After | Autentikasi sebelum batas user; storage limits yang sudah terpasang |
| Query | Eager User.toko, eager items/customer pada list pesanan | JWT, toko/produk/pesanan/laporan; locking detail tetap terpisah |
| Pagination | Count/filter/order stabil dan envelope opsional | Legacy Dio List tetap utuh; page kosong dan ownership dites |
| Skema | Index status pesanan dan kategori produk | Satu migrasi; index toko dan unique email yang ada tidak diduplikasi |
| Validasi | Batas/formats field dan pesan Indonesia spesifik | Semua mutasi, query, UUID, JSON rusak; kontrak role register tetap aman |
| Keamanan | CORS env, docs/internal non-dev, JWT dan foto publik terkontrol | Refresh/Google tetap jalur pertukaran kredensial, tidak dipaksa access JWT |
| Operasional | Health SELECT 1, komponen DB dan versi, 503 saat DB gagal | Tidak mengubah transaksi/order snapshot atau alur bisnis |

## ADR: kontrak dan query

Default array dipertahankan karena shared ProdukApi/PesananApi memakai
`dio.get<List<dynamic>>`; Beranda juga menghitung statistik dari seluruh array.
Paginasi eksplisit memungkinkan backend ditingkatkan tanpa mengubah aplikasi.
Ini keputusan implementasi untuk memenuhi larangan merusak kontrak Flutter,
bukan klaim persetujuan pengguna atas pertanyaan opsional yang belum dijawab.

Target list pesanan: satu SELECT autentikasi+toko, satu COUNT, satu SELECT
pesanan dengan eager items/customer. Maksimal tiga SQL termasuk autentikasi
dan count, pada halaman berisi maupun kosong. Detail yang mengunci pesanan
tetap selectinload agar PostgreSQL tidak mengunci nullable outer join.

Invoice dan webhook belum diimplementasikan. Karena A5 melarang fitur bisnis
baru, keduanya tetap 404. Batas invoice dan verifikasi webhook tidak boleh
dilaporkan telah berjalan pada endpoint yang belum ada.

## Urutan dan bukti

1. Baseline seluruh tes SQLite/PostgreSQL, simpan hasil tanpa kredensial.
2. Jalur vertikal tes gagal lalu perbaikan: health/logging, rate limit,
   query/pagination, index/migrasi, validasi/keamanan.
3. Ulang semua tes, Ruff, import/compile, Compose config, migration upgrade,
   downgrade dan metadata check PostgreSQL. Hitung SQL saat 20 order dengan items.
4. Matriks HTTP seluruh route: sukses, tanpa JWT, UUID salah, JSON rusak,
   kosong/negatif/terlalu panjang, kepemilikan, batas 429 dan DB mati 503.
5. Review independen read-only, perbaiki temuan, tulis hasil aktual dan curl.
6. Commit kecil per jalur yang lulus, hanya file A5. Perubahan pengguna yang
   sudah ada, termasuk seller_shell.dart, tetap utuh dan tidak ikut commit.

Tidak mengklaim aman untuk semua input yang mungkin. Pernyataan kesiapan A5
hanya diberikan setelah gate yang tersedia lulus dan gap dilaporkan.

## Hasil akhir 21 Oktober 2026

- 138 tes lulus tanpa skip, termasuk PostgreSQL nyata, konkurensi dan migrasi.
- 369 pemeriksaan HTTP SQLite/PostgreSQL/Docker prod, expected sama dengan actual,
  tidak ada500 pada matriks acceptance. Fault injection500 hanya untuk tes logger.
- Rate limit login6/register4/mutasi61, health DBdown503, prod internal404 dan
  pagination100 diulang pada container sebenarnya. Log tidak memuat marker query,
  password atau token uji. Source45file Python container sama dengan host.
- Migrasi live0004_query_indexes head dan Alembic check bersih; container/schema
  uji sudah dibersihkan. Backend utama tetap ENVdev dan health200.
- Review query/index serta keamanan selesai; temuan P1/P2 sudah ditutup.
- Tidak ada perubahan Flutter dari A5. Tombol Toko membutuhkan pengecualian UI
  yang belum dijawab. Payment/webhook belum dibangun, Redis aktif multiworker
  dan deployment internet belum diuji. Batas tersebut ada di A5_API.md.

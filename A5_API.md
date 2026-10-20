# Backend A5

Hasil 21 Oktober 2026: 138 tes lulus tanpa skip, 369 pemeriksaan HTTP dengan
expected sama dengan actual, tidak ada 500 pada matriks acceptance.
Backend dinyatakan production-ready fase A5.

Pernyataan ini berlaku untuk endpoint seller yang sudah tersedia dan deployment
satu proses yang diuji. Pembayaran/invoice dan webhook Xendit belum ada pada
A1-A4; keduanya tidak dibuat karena A5 melarang fitur bisnis baru. Batas invoice
10/menit dan verifikasi XENDIT_WEBHOOK_TOKEN belum dapat dinyatakan terverifikasi.
Deployment internet, beban produksi, dan Redis bersama belum diuji.

## Kontrak yang dipertahankan

- Request GET /produk dan /pesanan tanpa page/per_page tetap array lengkap.
  Ini menjaga Dio List dan statistik Beranda yang memakai seluruh pesanan.
- Dengan page atau per_page, hasil menjadi `{data: [...], meta: {...}}`.
  Default page=1, per_page=20, maksimum 100. Nilai 200 dibatasi menjadi 100;
  nilai nol/negatif, teks, dan page di atas 2147483647 menghasilkan 422.
- Meta berisi page, per_page, total milik toko sesuai filter, dan total_pages.
  Hasil kosong mempunyai total_pages=0. Semua field item lama tetap tersedia.
- Route bisnis memerlukan JWT seller. Google login tetap memakai ID token
  Google, refresh memakai refresh token, dan /uploads/* tetap publik untuk URL
  foto produk yang sudah digunakan Flutter. Tidak ada akses bisnis publik baru.
- Mutasi tetap mempertahankan transisi status, snapshot harga, undo, dan row lock
  PostgreSQL. Tidak mengubah transaksi laporan satu statement SQL.

## Perubahan per file

Semua path di tabel relatif terhadap backend/, kecuali yang diberi awalan root.

| File | Perubahan dan alasan |
| --- | --- |
| app/main.py | Hubungkan middleware/dependency, health SELECT 1 dengan versi, 503 jika DB gagal |
| app/core/request_log.py | JSON ke stderr, ID UUID, durasi/status/user; traceback dan fallback error ber-CORS |
| app/core/rate_limit.py | Login5/IP, register3/IP, mutasi60/user; sisa detik dan Retry-After; storage gagal503 |
| app/core/security.py | Ambil User beserta toko dalam satu query; catat user dan terapkan kuota mutasi |
| app/core/config.py | Tolak wildcard dan origin CORS ber-path di luar dev; sembunyikan input config pada error |
| app/core/cors.py | CORS dari env, expose ID/Retry-After, docs/internal non-dev404 sebelum parsing body |
| app/core/validation.py | Pesan422 Indonesia berdasarkan field/batas; JSON >100tingkat dan integer tak terbaca400 |
| app/schemas/input.py | Tolak NUL pada input dengan traversal iteratif tanpa RecursionError |
| app/schemas/auth.py | Batas panjang email/password/token dan format telepon; role register tetap tidak bisa dipilih |
| app/schemas/toko.py | Format telepon, nama nonkosong eksplisit, boolean jadwal ketat dan status extra-forbid |
| app/schemas/produk.py | Input aman dan boolean tersedia ketat; batas integer lama tetap |
| app/schemas/pesanan.py | Input aman untuk item, dummy, alasan dan status |
| app/schemas/pagination.py | Definisi response data/meta yang terdokumentasi OpenAPI dev |
| app/models/user.py | Relasi toko satu pemilik, lazy=raise agar lookup tidak memicu SQL tersembunyi |
| app/models/produk.py | Metadata index kategori |
| app/models/pesanan.py | Metadata index status |
| app/services/toko.py | Gunakan relasi toko yang sudah eager-loaded saat autentikasi |
| app/services/pagination.py | Filter/count/offset/limit yang sama dan urutan stabil untuk dua list |
| app/routers/auth.py | Hubungkan limiter register/refresh dan user_id pada log login |
| app/routers/produk.py | Query NUL ditolak dan pagination opsional |
| app/routers/pesanan.py | Joinedload items/customer pada list, unique parent, pagination; detail terkunci tetap selectinload |
| app/db/migrations/versions/0004_query_indexes.py | Tambah hanya index status pesanan dan kategori produk; downgrade simetris |
| Dockerfile | Nonaktifkan access log Uvicorn supaya query berisi rahasia tidak tercetak oleh logger kedua |
| tests/test_a5_observability.py | Health DBdown, JSON log/privacy, traceback dan CORS fallback |
| tests/test_a5_rate_limit.py | Login6/register4/mutasi61, isolasi user dan storage Redis mati |
| tests/test_a5_validation.py | NUL/telepon/range/UUID/pesan batas dan nested field1000tingkat |
| tests/test_a5_security.py | CORS, docs dev/prod, internal404 bahkan JSON rusak |
| tests/test_a5_queries.py | Ukur seluruh SQL pada20order/items/customer, SQLite dan PostgreSQL |
| tests/test_a5_pagination.py | Legacy/full list, filter, cap100, empty page, SQL<=3 dan parent dengan beberapa item |
| tests/test_a5_migration.py | Upgrade/downgrade/check, data lama dan unique email tetap ada di dua DB |
| tests/test_a5_acceptance.py | Seluruh route, alur sukses, JWT hilang, UUID/JSON/NUL/integer besar; ekspor matriks |
| root A5_PLAN.md | Rencana, keputusan kontrak, dampak dan batas cakupan |
| root artifacts/a5/* | Matriks expected/actual, JUnit dan bukti runtime |
| root MISTAKES.md | Penyebab dan pengaman untuk temuan validasi/logging |
| root handoff.md | Status nyata dan kelanjutan |

Index toko_id pada produk/pesanan sudah ada dari A2/A3. Email users sudah UNIQUE,
sehingga PostgreSQL memiliki unique index; tidak membuat index email duplikat.
Migrasi live sudah 0004_query_indexes dan `alembic check` tidak menemukan perubahan.

## Rate limit dan log

Login Google memakai bucket login yang sama. Login/register dihitung setelah
body lolos validasi, termasuk percobaan kredensial salah atau akun duplikat.
Kuota mutasi berlaku bersama lintas route untuk user JWT yang sudah diverifikasi;
refresh token juga dibatasi per user. GET tetap dapat dipakai setelah kuota habis.
Header X-Forwarded-For yang tidak dipercaya tidak mengganti identitas peer pada tes.

429 mempunyai detail `Terlalu banyak permintaan, coba lagi dalam N detik` dan
Retry-After sesuai sisa jendela fixed-window. Default memory:// berlaku untuk
satu proses yang diuji. Untuk beberapa worker/instance, arahkan
RATE_LIMIT_STORAGE_URI ke satu Redis bersama; storage gagal menghasilkan503,
bukan menghapus batas secara diam-diam. Redis aktif bersama belum diuji.

Log request berisi timestamp, request_id, method, path tanpa query, status_code,
duration_ms dan user_id atau null jika identitas belum terverifikasi. Semua respons
mendapat X-Request-ID, termasuk validasi,429,404 dan fallback500/503. Exception
tak terduga dicatat dengan traceback penuh ke stderr. Parameter SQL disembunyikan.
Tes fault injection sengaja menghasilkan500 untuk membuktikan traceback; ini
terpisah dari369 input acceptance yang tidak menghasilkan500.

## Contoh curl

Gunakan akun uji. API di bawah adalah backend lokal yang diverifikasi. Isi TOKEN,
REFRESH_TOKEN, PRODUK_ID dan PESANAN_ID dari respons nyata; FOTO menunjuk file
jpg/png/webp lokal. Contoh mutasi pesanan memerlukan urutan status yang benar.

```bash
API=http://127.0.0.1:8000
TOKEN='isi-access-token-akun-uji'
REFRESH_TOKEN='isi-refresh-token-akun-uji'
PRODUK_ID='isi-uuid-produk'
PESANAN_ID='isi-uuid-pesanan'
FOTO='/path/ke/foto-uji.png'

curl -i "$API/health"
curl -i --json '{"nama_pemilik":"Pemilik Uji","nama_toko":"Toko Uji","email":"seller@example.com","password":"SandiContoh123!"}' "$API/auth/register"
curl -i --json '{"email":"seller@example.com","password":"SandiContoh123!"}' "$API/auth/login"
curl -i --json '{"id_token":"isi-id-token-google"}' "$API/auth/google"
curl -i --json "{\"refresh_token\":\"$REFRESH_TOKEN\"}" "$API/auth/refresh"
curl -i -H "Authorization: Bearer $TOKEN" "$API/auth/me"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" --json '{"fcm_token":"token-notifikasi-uji"}' "$API/auth/fcm-token"

curl -i -H "Authorization: Bearer $TOKEN" "$API/toko/me"
curl -i -X PUT -H "Authorization: Bearer $TOKEN" --json '{"nama":"Toko Uji Baru","alamat":"Jalan Uji 1","telepon":"081234567890"}' "$API/toko/me"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" --json '{"status":"buka"}' "$API/toko/me/status"
curl -sS -H "Authorization: Bearer $TOKEN" "$API/toko/me/jam-buka" > /tmp/jam-buka-uji.json
curl -i -X PUT -H "Authorization: Bearer $TOKEN" --json @/tmp/jam-buka-uji.json "$API/toko/me/jam-buka"

curl -i -H "Authorization: Bearer $TOKEN" "$API/produk"
curl -i -H "Authorization: Bearer $TOKEN" "$API/produk?page=1&per_page=200&q=Beras&kategori=Beras"
curl -i -H "Authorization: Bearer $TOKEN" --json '{"nama":"Beras","harga":15000,"stok":5,"satuan":"kg","kategori":"Beras"}' "$API/produk"
curl -i -H "Authorization: Bearer $TOKEN" "$API/produk/$PRODUK_ID"
curl -i -X PUT -H "Authorization: Bearer $TOKEN" --json '{"harga":16000}' "$API/produk/$PRODUK_ID"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" "$API/produk/$PRODUK_ID/toggle"
curl -i -H "Authorization: Bearer $TOKEN" -F "file=@$FOTO" "$API/produk/$PRODUK_ID/foto"
curl -i -X DELETE -H "Authorization: Bearer $TOKEN" "$API/produk/$PRODUK_ID"

curl -i -H "Authorization: Bearer $TOKEN" "$API/pesanan"
curl -i -H "Authorization: Bearer $TOKEN" "$API/pesanan?page=1&per_page=20&status=baru"
curl -i -H "Authorization: Bearer $TOKEN" "$API/pesanan/$PESANAN_ID"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" "$API/pesanan/$PESANAN_ID/terima"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" "$API/pesanan/$PESANAN_ID/urungkan"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" --json '{"alasan":"Stok Habis"}' "$API/pesanan/$PESANAN_ID/tolak"
curl -i -X PATCH -H "Authorization: Bearer $TOKEN" --json '{"status":"dikemas"}' "$API/pesanan/$PESANAN_ID/status"
curl -i -H "Authorization: Bearer $TOKEN" --json '{}' "$API/pesanan/internal/test"

curl -i -H "Authorization: Bearer $TOKEN" "$API/laporan/ringkasan?range=7h"
curl -i -H "Authorization: Bearer $TOKEN" "$API/laporan/produk-terlaris?range=30h&limit=5"
```

Upload mengembalikan foto_url; GET URL itu tetap publik dan melayani hanya nama
file yang dihasilkan backend. Dummy internal hanya tersedia saat ENV=dev.
Di prod, dummy, /docs, /redoc, /openapi.json dan /docs/oauth2-redirect selalu404.
Tidak ada contoh invoice/webhook yang diklaim bekerja karena endpoint belum ada.

## Reproduksi tes

Dari backend/, gunakan environment DB pengujian PostgreSQL yang dapat membuat
schema terisolasi. Set A2_TEST_POSTGRES_URL dan JWT/DATABASE_URL untuk Alembic
sesuai environment lokal. Fixture tes membuat lalu menghapus schema sendiri.

```bash
.venv/bin/ruff check app tests
.venv/bin/python -m compileall -q app
A5_REPORT_DIR=/tmp/grocery-a5-matrix .venv/bin/python -m pytest -q --junitxml=/tmp/a5-junit.xml
.venv/bin/python -m alembic current
.venv/bin/python -m alembic check
docker compose config --quiet
```

Tanpa A2_TEST_POSTGRES_URL, tes PG akan skip; hasil138lulus yang dilaporkan memakai
PG nyata dan tidak mempunyai skip. Rate limit, health503 dan prod404 juga diulang
melalui container production dengan schema sementara. Schema/container uji sudah
dihapus; backend lokal utama tetap ENV=dev dan health200.

## Tombol buka/tutup di menu Toko

Backend PATCH /toko/me/status berhasil mengubah buka dan tutup dalam alur HTTP
sukses. Masalah menu ada di apps/seller/lib/features/store/presentation/toko_screen.dart:
indikatornya `Chip` tanpa callback. Beranda memakai ActionChip yang memanggil
TokoApi.updateStatus melalui StoreNotifier.mutate. Perbaikan minimum adalah
menggunakan alur yang sama pada menu Toko, termasuk busy/error/refresh state.

Tidak ada file Flutter diubah pada A5. Pengecualian tombol beserta tes widgetnya
masih menunggu jawaban pengguna karena permintaan fase ini melarang perubahan UI.

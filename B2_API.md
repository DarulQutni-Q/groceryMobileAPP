# B2: katalog dan keranjang customer

B2 menambahkan katalog customer dan keranjang lokal per akun. Seller tetap memakai
kontrak sebelumnya. Tidak ada migrasi skema database pada fase ini.

## Endpoint

Semua endpoint di bawah memerlukan JWT. Customer hanya membaca produk tersedia
milik toko buka. Produk stok0 tetap ditampilkan dengan status Habis.

| Endpoint | Perubahan | Respons customer |
| --- | --- | --- |
| GET /produk | Tambah akses customer; q, kategori, toko_id, page, per_page | data + meta |
| GET /produk/{id} | Tambah akses customer, produk tersembunyi/toko tutup404 | Produk |
| GET /toko | Baru, hanya toko buka, pagination | data + meta |
| GET /toko/{id} | Baru, profil publik + produk tersedia berhalaman | profil + produk + meta |
| GET /kategori | Baru, kategori unik katalog yang dapat dibaca | array string |
| GET /promo | Baru, data demo B2 berlabel is_demo, TODO eksplisit di backend | array promo |

page default1, per_page default20 dan maksimal100; per_page200 dibatasi100.
Schema publik toko tidak mengirim owner_id/rekening_bank. Jam buka/tutup adalah
jadwal hari ini di WIB, null jika belum diatur. Detail toko menerima pagination
untuk field produk. Semua mutasi produk/toko tetap seller-only403 untuk customer.
GET /produk seller tanpa pagination tetap array, termasuk produknya yang disembunyikan.

```bash
BASE=http://127.0.0.1:8000
# Isi TOKEN, TOKO_ID, dan PRODUK_ID dengan akun/data lokal milikmu.
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/produk?q=indomie"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/produk?kategori=Beras"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/produk?toko_id=$TOKO_ID&page=2&per_page=5"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/produk/$PRODUK_ID"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/toko?page=1&per_page=20"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/toko/$TOKO_ID?per_page=5"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/kategori"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/promo"
```

Contoh meta: {"page":2,"per_page":5,"total":13,"total_pages":3}.
Endpoint produk dan toko list memakai maksimal3 query termasuk autentikasi;
detail toko4 query tetap, tanpa query per produk. Tes melindungi batas list.

## Perubahan per file

| File | Alasan |
| --- | --- |
| backend/app/main.py | Memasang router katalog setelah route literal /toko/me |
| backend/app/routers/produk.py | Cabang baca customer tanpa melonggarkan dependency mutasi seller |
| backend/app/routers/catalog.py | Endpoint toko publik, kategori dan promo demo |
| backend/app/services/catalog.py | Filter visibilitas, paging dan jadwal hari ini tanpa N+1 |
| backend/app/schemas/catalog.py | Memisahkan field publik dan field privat toko |
| backend/app/schemas/produk.py | Menormalkan timestamp UTC, termasuk hasil SQLite yang kehilangan tzinfo |
| backend/tests/test_catalog.py | Kontrak HTTP, privasi, ownership, input salah dan jumlah query pada SQLite/PostgreSQL |
| backend/tests/test_customer_auth.py | Kontrak B1 baca produk403 berubah eksplisit menjadi katalog200; semua larangan mutasi tetap |
| packages/shared/lib/src/models/halaman.dart | Envelope pagination bertipe |
| packages/shared/lib/src/models/promo.dart | Promo API dengan penanda demo |
| packages/shared/lib/src/models/toko.dart | Jam buka/tutup opsional, kompatibel data seller |
| packages/shared/lib/src/models/produk.dart | Serialisasi snapshot produk untuk keranjang lokal |
| packages/shared/lib/src/models/keranjang.dart | Item, qty, pilihan, jumlah dan subtotal terhitung |
| packages/shared/lib/src/api/produk_api.dart | listHalaman/kategori baru; list seller dipertahankan |
| packages/shared/lib/src/api/toko_api.dart | List/detail publik; API profil seller dipertahankan |
| packages/shared/lib/src/api/promo_api.dart | Mengambil promo dari backend |
| packages/shared/lib/src/providers/keranjang_provider.dart | Antrean mutasi/restore, stok, satu toko, pemisahan akun dan recovery storage |
| packages/shared/lib/src/core/secure_storage.dart | Penyimpanan cart terenkripsi; error operasi diteruskan ke caller tanpa meracuni antrean berikutnya |
| packages/shared/lib/shared.dart, pubspec.yaml, pubspec.lock | Export model/API/provider dan dependency Riverpod |
| packages/shared/test/catalog_api_test.dart | Query parameter dan parsing metadata/jam/promo |
| packages/shared/test/keranjang_test.dart | Stok, qty, pilihan, subtotal, restart, akun, gagal simpan dan race |
| packages/shared/test/api_client_test.dart | Gagal menulis cart tidak memblokir pembacaan token/cart |
| apps/customer/lib/app.dart | Shell customer sebagai route root; Back Android dan pergantian sesi diuji |
| apps/customer/lib/features/catalog/application/produk_provider.dart | Debounce500ms, kategori, pagination, retry dan mengabaikan respons lama |
| apps/customer/lib/features/catalog/presentation/customer_shell.dart | Lima tab sesuai acuan; logout melalui Akun |
| apps/customer/lib/features/catalog/presentation/home_page.dart | Banner, member, kategori, countdown, pencarian dan rail/katalog produk |
| apps/customer/lib/features/catalog/presentation/product_page.dart | Detail aktual, stok, qty, tambah dan Beli Sekarang ke keranjang |
| apps/customer/lib/features/catalog/presentation/cart_page.dart | Pilihan, subtotal, qty, hapus animasi, info toko dan rincian biaya |
| apps/customer/lib/features/catalog/presentation/catalog_widgets.dart | Foto cache/fallback, Rupiah, countdown dan konfirmasi berganti toko |
| apps/customer/pubspec.yaml, pubspec.lock | cached_network_image dengan placeholder/error widget |
| apps/customer/test/catalog_state_test.dart | Debounce, filter, pagination, race request dan retry |
| apps/customer/test/catalog_flow_test.dart | Browse/detail/cart, badge, hitungan, hapus, clear search, Back dan layar kecil |
| apps/customer/test/countdown_test.dart | Waktu lokal23:59, detik, nol dan pergantian hari |
| apps/customer/integration_test/catalog_test.dart | Perjalanan Android dengan API lokal nyata |
| apps/customer/test_driver/catalog_test.dart | Screenshot perjalanan B2 ke artifacts/b2 |
| scripts/smoke_catalog.py | Akun/produk uji terpisah dan49 pemeriksaan HTTP tanpa mencetak kredensial |
| B2_PLAN.md, artifacts/b2, handoff.md, MISTAKES.md | Keputusan, bukti, batas dan kontinuitas |

## Kontrak keranjang

Satu toko per keranjang; menambah produk toko lain membuka konfirmasi sebelum
mengganti isi. Batal mempertahankan isi lama. Snapshot disimpan terenkripsi dalam
key customer_cart_{user_id}; logout tidak menghapus belanja akun tersebut dan
akun lain mempunyai key berbeda. Qty0 menghapus item. Qty melebihi stok ditolak.
Tombol plus memakai increment dalam antrean, sehingga tap cepat saat storage
lambat tidak hilang. Subtotal/Checkout menghitung item yang dicentang; badge tas
menghitung seluruh qty. Gagal simpan menampilkan error dan mengembalikan state;
JSON cart rusak memerlukan retry atau kosongkan secara eksplisit.

Produk/harga/stok adalah snapshot terakhir, belum reservasi stok. B3 harus
memvalidasi ulang harga, ketersediaan dan stok di server sebelum checkout.
Beli Sekarang pada B2 menambah qty pilihan lalu membuka keranjang. Voucher,
checkout, scan, tagihan, pelacakan dan tab lanjutan menampilkan Segera hadir.

## Acuan dan batas

Acuan aktual bernama Pasted image(5)/(6)/(8).png, bukan01-main-cluster.png;
roadmap bertahap yang disebut attachment tidak ditemukan. PRD/design/rules
aktual berada di root. Keputusan kerja telah disampaikan: satu toko dan memakai
harga asli. Pertanyaan preferensi tetap terbuka, tidak dicatat sebagai persetujuan.

Harga coret, diskon dan deskripsi belum ada dalam model backend. Tidak menambah
kolom tanpa kebutuhan B2: diskon/harga coret dan banner hemat disembunyikan,
deskripsi menampilkan -. Angka poin/stempel/barcode dan voucher adalah tampilan
demo yang diizinkan. Tidak mengklaim voucher sudah dapat digunakan atau diskon
50% berlaku pada produk. Nama/harga/jumlah mengikuti data aktual meskipun contoh
screenshot berbeda. Foto asli tidak disertakan untuk produk uji; fallback tampak
pada screenshot, sementara foto_url yang tersedia memakai cache dan error widget.
Tidak mengklaim pixel-identik; ikon kategori memakai Material3 dan teks besar
menyesuaikan layout. Lokasi terdekat/ETA belum dihitung GPS: header memakai toko
buka pertama dari API dan ETA statis15–20menit sesuai cakupan fase ini.

Tidak mengedit apps/seller atau perubahan pengguna pada A3, README, CONTEXT,
root specs dan docs. Diff awal pengguna dibandingkan kembali sebelum selesai.
Build iOS, perangkat fisik dan deploy staging/production belum diuji.
Cold start native lintas proses belum tuntas karena emulator berulang kali
terputus; persistensi shared dan restart widget aplikasi pada journey lulus.

Perintah verifikasi dan hasil aktual ada di artifacts/b2/README.md dan lognya.

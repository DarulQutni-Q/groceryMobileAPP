# Bukti B3, 21 Oktober 2026

Alamat dan checkout COD sampai sukses telah berjalan di Android dengan backend
PostgreSQL nyata. Integrasi Xendit tersedia, tetapi pembayaran sandbox nyata
belum dijalankan karena kedua kredensial belum tersedia. Tidak ada screenshot
halaman Xendit dan tidak ada klaim pembayaran QRIS sungguhan berhasil.

## Hasil pemeriksaan

| Pemeriksaan | Hasil |
| --- | --- |
| Backend lengkap, SQLite/PostgreSQL | 224 passed, 2 skipped |
| Shared | 34 tes lulus; analyze bersih |
| Customer | 26 tes lulus; analyze bersih |
| Seller, regresi tanpa edit sumber | 32 tes lulus; analyze bersih |
| Total tes otomatis yang lulus | 316 |
| HTTP ke backend lokal | 36 request sesuai expected; 0 respons 500 |
| Android dengan backend nyata | COD dua produk, alamat, sukses, cart kosong lulus |
| APK dev normal | Build/install/login UI/cold start dan restore sesi lulus |
| Migrasi | Upgrade/downgrade SQLite/PostgreSQL dan metadata lulus |
| QRIS/VA/e-wallet sandbox nyata | Belum diuji, kredensial belum tersedia |

Dua skip hanya varian SQLite untuk row locking concurrent. Kedua tes yang
sama dijalankan dan lulus di PostgreSQL. Bukan tes pembayaran yang disembunyikan.
Tes backend memakai schema PostgreSQL acak; tidak menghapus data aplikasi lokal.

Lihat [log backend](backend-tests.txt), [log customer](customer-tests.txt),
[analyze customer](customer-analyze.txt), [journey Android](android-journey.txt),
[HTTP per endpoint](http-results.md), [metadata pemeriksaan](checks.json),
[perubahan per file](changes.md), dan [git log](git-log.txt).

## Cakupan tes di batas API dan UI

| Jalur | Input/kejadian | Expected | Actual |
| --- | --- | --- | --- |
| Alamat | CRUD, ganti utama, hapus utama | Tepat satu utama bila alamat ada | Lulus dua DB |
| Alamat | Milik akun lain | 403, data tetap | Lulus dua DB dan HTTP lokal |
| Validasi | Kosong, HP bercampur huruf, koordinat salah | 422 Indonesia | Lulus dua DB |
| Checkout | Dua produk COD, harga DB | 201, biaya 1.000, payment pending | Lulus API dan Android |
| Checkout | Harga client tambahan | 422, tidak membuat order | Lulus dua DB dan HTTP lokal |
| Checkout | Qty melebihi stok | 400, order/items/stok tetap | Lulus dua DB dan HTTP lokal |
| Checkout | JSON rusak/UUID ngawur | 422, tidak500 | Lulus dua DB dan HTTP lokal |
| Checkout | DB gagal setelah order flush | 503, seluruh order/items/stok rollback | Lulus dua DB |
| Checkout | Dua customer membeli stok terakhir | Hanya satu201, satu400, stok tidak negatif | Lulus PostgreSQL |
| Checkout | Key dan payload sama | Order/invoice tidak digandakan | Lulus dua DB dan HTTP lokal |
| Checkout | Timeout respons invoice | Rekonsiliasi GET, tidak POST invoice kedua | Lulus transport terkontrol dua DB |
| Checkout | Outcome invoice tidak diketahui | 503; key dipertahankan | Lulus transport terkontrol dua DB |
| Checkout | Belum ada konfigurasi callback | 503 sebelum membuat invoice | Lulus dua DB |
| Webhook | Token salah/tidak ada | 403 | Lulus dua DB dan HTTP lokal |
| Webhook | PAID benar, kemudian duplikat/EXPIRED | Tetap paid, stok tidak dipotong ulang | Lulus transport terkontrol dua DB |
| Webhook | Identitas/nominal salah | 400/422, tidak mengubah pembayaran | Lulus dua DB |
| Webhook | Datang sebelum respons invoice | Tidak menurunkan PAID menjadi pending | Lulus PostgreSQL |
| Webhook | PAID setelah batal | Rekam dana+marker, order tetap batal, 409 | Lulus dua DB |
| Seller | Membatalkan pesanan lunas | Tetap paid, rekonsiliasi true, stok pulih sekali | Lulus dua DB |
| Rate limit | Checkout request ke-11 dalam semenit | 429 dan Retry-After | Lulus dua DB |
| Polling UI | Pending lalu paid, tiap 3 detik | Sukses satu kali, polling berhenti | Lulus widget |
| Polling UI | Pending dua menit atau layar ditutup | Polling berhenti | Lulus widget |
| Finalisasi UI | Cart storage gagal setelah paid | Retry lokal, key lama, bukan invoice baru | Lulus widget |
| Resume UI | Cart kosong, sesi pembayaran tersimpan | Dapat dibuka dari Akun dengan key sama | Lulus widget |
| Sesi | Alamat/catatan berubah, akun berbeda | Snapshot dipertahankan, akun terisolasi | Lulus unit |

Transport terkontrol mengganti HTTP ke Xendit, memakai request FastAPI dan DB
sesungguhnya. Invoice URL dalam fixture bukan bukti invoice sandbox nyata.
HTTP lokal mengharapkan503 untuk QRIS yang belum dikonfigurasi; status itu tidak
dihitung sebagai pembayaran berhasil. File http-proof.json memisahkan expected
dan actual untuk setiap request.

## Screenshot Android

Semua PNG telah dibuka dan diperiksa, tanpa bingkai ponsel buatan.

| File | Layar |
| --- | --- |
| [01-form-alamat.png](01-form-alamat.png) | Form berisi label/nama/HP/alamat/patokan |
| [02-daftar-alamat.png](02-daftar-alamat.png) | Alamat utama dan alamat tambahan |
| [03-konfirmasi.png](03-konfirmasi.png) | Alamat dipilih dan ringkasan dua barang |
| [04-metode-bayar.png](04-metode-bayar.png) | Tujuh metode, QRIS recommended |
| [05-rincian-cod.png](05-rincian-cod.png) | Subtotal 17.000 + layanan 1.000 =18.000 |
| [06-sukses-cod.png](06-sukses-cod.png) | Kode DG dan sukses pembuatan pesanan |
| [07-keranjang-kosong.png](07-keranjang-kosong.png) | Cart kosong sesudah sukses |
| [08-home-apk-normal.png](08-home-apk-normal.png) | Home normal sesudah force-stop/reopen |

Journey menyiapkan login dan dua item cart melalui API/storage lalu menjalankan
interaksi alamat dan checkout melalui UI. Setelahnya APK normal dipasang,
login dilakukan lewat field UI dengan Ingat Saya, proses dimatikan, lalu Home
terlihat otomatis saat dibuka kembali. Instalasi normal awal menampilkan splash;
itu tidak dihitung sebagai restore login sampai uji setelah login UI ini lulus.

## Menjalankan ulang

Gunakan database lokal terpisah dan environment yang sudah disiapkan. Perintah
smoke membuat akun/data uji dan menyimpan kredensial hanya di file privat /tmp.

```bash
python scripts/smoke_checkout.py --base-url http://127.0.0.1:8000 \
  --proof-file /tmp/b3-http-proof.json --session-file /tmp/b3-session.json
cd backend
.venv/bin/python -m pytest -q
.venv/bin/ruff check app tests
```

Set A2_TEST_POSTGRES_URL melalui environment privat untuk menjalankan varian
PostgreSQL; tanpa itu tes terkait PostgreSQL akan skip. Jangan memakai URL DB
rahasia sebagai argumen shell atau menyimpannya di repo.

Flutter: jalankan flutter test dan flutter analyze di packages/shared,
apps/customer, serta apps/seller. APK normal:

```bash
cd apps/customer
flutter build apk --debug --flavor dev --target lib/main_dev.dart
flutter drive --flavor dev --driver=test_driver/checkout_test.dart \
  --target=integration_test/checkout_test.dart \
  --dart-define-from-file=/tmp/b3-emulator-defines.json -d emulator-5554
```

File define privat memuat B3_ACCOUNT, B3_PASSWORD, B3_PRODUCT_1, B3_PRODUCT_2
dari akun/produk smoke. Jangan commit file define atau APK pengujian yang
memuatnya. APK normal tersedia pada build/app/outputs/flutter-apk/app-dev-debug.apk
di apps/customer; file unduhan telah dikembalikan ke APK normal sesudah journey.

Peringatan lingkungan yang terlihat: buildx tidak terpasang sehingga Docker
memakai classic builder; metadata SDK XML versi 4 dibaca tool versi 3; emulator
mencatat timeout frame tracker IME. Build dan assertion perjalanan tetap lulus.
Tidak menutupi peringatan ini dengan ignore/skip pada tes.

Belum diverifikasi: pembayaran sandbox nyata beserta halaman browsernya, semua
channel VA/e-wallet secara end-to-end, iOS/perangkat fisik, dan deploy staging/prod.
Untuk melanjutkan pembayaran nyata, ikuti B3_API.md setelah kredensial tersedia.

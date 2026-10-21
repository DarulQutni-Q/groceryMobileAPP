# Bukti B2 customer

Seluruh 246 tes lulus: backend 164, shared 32, customer 18, seller 32.
Analyze shared/customer/seller: No issues found. Satu journey Android nyata
juga lulus, ditambah 49 request HTTP lokal expected=actual dan nol respons 500.

| Seam | Input / tindakan | Expected | Actual |
| --- | --- | --- | --- |
| GET /produk | q=indomie + toko_id uji | Hanya Indomie |200, ID sesuai |
| GET /produk | kategori=Beras + toko_id uji | Hanya Beras |200,10 produk Beras |
| GET /produk | page2/per_page5 + toko_id uji |5 data, meta2/5/13/3 | Sesuai |
| GET /produk | per_page200 | Cap 100 |200, meta.per_page100 |
| GET /produk/{id} | Produk tersedia | Detail aktual |200 |
| GET /produk/{id} | Tersembunyi / UUID acak |404 |404 |
| GET /toko | JWT customer | Toko buka, tanpa field privat |200, tidak ada owner_id/rekening_bank |
| GET /toko/{id} | per_page5 | Profil,5 produk, jadwal hari ini |200, jam_tutup23:00 |
| GET /kategori | JWT customer | Kategori unik terlihat |200, mencakup Beras/Mie/Minyak/Susu |
| GET /promo | JWT customer | Demo eksplisit |200, is_demo=true |
| GET katalog | Tanpa JWT |401 |401 |
| GET produk/toko | UUID salah, page0, per_page-1, q=NUL |422 |422 |
| POST produk, PATCH toggle/status | JWT customer |403 |403 |
| GET toko/produk | Seller menutup toko uji |404 / data kosong | Sesuai |
| GET produk seller | Tanpa query pagination | Array lama |200 array |
| Daftar produk/toko | Hitung SQL termasuk JWT | Maksimal 3 query | Tes SQLite dan PostgreSQL lulus |
| Search provider | Ketik cepat | Tunggu 500 ms, query terakhir | Lulus |
| Search/provider | Kategori, halaman berikut, respons lama, gagal muat | Filter gabungan, merge, stale diabaikan, retry | Lulus |
| Cart state | Qty, pilihan, stok0/lebih, qty0 | Subtotal benar, batas stok, hapus | Lulus |
| Cart storage | Restart / akun berbeda / JSON rusak | Restore / terpisah / error tampak | Lulus |
| Cart storage | Gagal write / read tertahan / tap plus beruntun | Rollback, token tetap terbaca, qty tidak hilang | Lulus |
| Widget | Browse/detail/add/badge/cart/qty/select/delete | State dan subtotal berubah sesuai tindakan | Lulus |
| Widget | System Back detail/cart | Kembali ke Home | Lulus |
| Widget | Tombol hapus search | Field kosong, request tanpa q | Lulus |
| Widget |320x640, skala teks1.3 | Tidak overflow | Lulus |
| Countdown |23:58:57 ->59 ->lewat ->hari berikut |03 ->02 ->00 ->23:59:00 | Lulus |
| Android emulator | Browse/search/filter/detail/add/cart/qty/restore/select/delete | Seluruh urutan berhasil | Lulus 22 detik, tanpa exception Flutter |

Bukti mentah: backend-tests.txt, shared-checks.txt, customer-checks.txt,
seller-checks.txt, android-journey.txt dan live-http.json. Log Android memuat
peringatan performa emulator/IME (FrameTracker), tanpa kegagalan tes. Builder
Docker lokal memakai classic builder karena plugin buildx tidak tersedia;
backend image tetap berhasil dibangun dan health200.

Screenshot perjalanan nyata:

- [01-beranda.png](/home/darulqutni/groceryMobileAPP/artifacts/b2/01-beranda.png): Home dengan data API dan promo demo.
- [02-detail-produk.png](/home/darulqutni/groceryMobileAPP/artifacts/b2/02-detail-produk.png): Produk API, harga/stok nyata dan deskripsi kosong.
- [03-keranjang-isi.png](/home/darulqutni/groceryMobileAPP/artifacts/b2/03-keranjang-isi.png):2 Indomie ×Rp16.200 =Rp32.400, jadwal toko aktual.
- [04-keranjang-kosong.png](/home/darulqutni/groceryMobileAPP/artifacts/b2/04-keranjang-kosong.png): Semua item terpilih dihapus, subtotal0.
- [05-home-apk-normal.png](/home/darulqutni/groceryMobileAPP/artifacts/b2/05-home-apk-normal.png): Home APK normal terbaru setelah login melalui UI.

APK normal dibuild tanpa target/define integration test, dipasang dan login
melalui UI HP. Tiga produk Beras ditambahkan lewat tombol dan badge3 diamati. Pemeriksaan
native cold start lintas proses belum tuntas: emulator terputus berulang dan
AVD yang dimulai lagi tidak memuat APK customer. Pengulangan dihentikan agar
tidak mengklaim hasil yang belum terverifikasi. Persistensi tetap diuji lewat
unit/shared dan bongkar-pasang widget aplikasi pada journey Android yang lulus.
Lanjutkan pemeriksaan lintas proses di emulator stabil atau perangkat fisik.
Git-log.txt adalah snapshot sebelum commit bukti akhir.

Foto produk seed belum diunggah, sehingga screenshot memakai fallback.
Harga coret/diskon tidak dibuat-buat. Detail variasi acuan dan gap visual ada
pada B2_API.md. Screenshot tidak membuktikan checkout/pembayaran sudah ada.

Perintah pengujian:

```bash
cd backend
# A2_TEST_POSTGRES_URL harus menunjuk PostgreSQL uji yang diizinkan.
.venv/bin/python -m pytest -q
.venv/bin/ruff check app tests
cd ../packages/shared
flutter analyze
flutter test
cd ../../apps/customer
flutter analyze
flutter test
flutter drive --driver=test_driver/catalog_test.dart \
  --target=integration_test/catalog_test.dart --flavor dev -d emulator-5554 \
  --dart-define=B2_ACCOUNT="$B2_ACCOUNT" --dart-define=B2_PASSWORD="$B2_PASSWORD"
flutter build apk --debug --flavor dev -t lib/main_dev.dart
cd ../seller
flutter analyze
flutter test
```

HTTP smoke membuat akun dan produk terpisah di backend lokal. File sesi wajib
di luar repository, mode0600; skrip tidak mencetak password/JWT:

```bash
python scripts/smoke_catalog.py --base-url http://127.0.0.1:8000 \
  --proof-file artifacts/b2/live-http.json --session-file /tmp/grocery-b2-session.json
```

Jangan menjalankan seed terhadap staging/production. PostgreSQL seam pytest
memakai schema acak a2_test_* dan membersihkannya; bukan tabel public aplikasi.
Build/signing iOS, perangkat fisik dan deploy belum diuji. Pengujian HTTP tidak
menjamin semua input tak terbatas bebas500; semua kasus yang dijalankan tanpa500.

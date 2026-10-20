# Daclanari Grocery, Fase A3

Seller mencakup akun, Beranda, produk, profil toko dan pesanan beserta backend. Customer belum dikerjakan. Laporan masih placeholder A4. UI mengacu pada gambar di `docs/screenshots/seller/`; kolom Email tambahan pada login dan daftar sudah disetujui. Bukti A3 dan batas referensi visual ada di `artifacts/a3/README.md`.

## Backend

Salin contoh environment, lalu isi password database dan JWT secret minimal 32 karakter. Jangan memakai `CHANGE_ME`. Contoh tidak berisi kredensial nyata.

```bash
cp .env.example .env
docker compose up --build -d
curl --fail http://localhost:8000/health
```

Container menjalankan `alembic upgrade head` sebelum Uvicorn. PostgreSQL ada di localhost:55432; API ada di localhost:8000. Port ini hanya di-bind ke loopback host. `GET /health` memeriksa koneksi database. Migrasi A2 membuat toko untuk akun A1 yang sudah ada; A3 menambah pesanan dan snapshot item. Foto produk disimpan pada volume `uploads_data`, terpisah dari container backend.

Backend default `ENV=prod`. Untuk pesanan dummy pengujian, aktifkan secara eksplisit pada backend lokal:

```bash
ENV=dev docker compose up -d --build backend
```

`POST /pesanan/internal/test` tetap membutuhkan JWT seller dan hanya tersedia pada `ENV=dev`. Semua nilai lainnya menghasilkan 404 tanpa membuat pesanan. Flavor dev Flutter tidak mengubah ENV backend.

Untuk menjalankan backend tanpa container, gunakan virtual environment dan isi environment dari `backend/.env.example`, kemudian:

```bash
cd backend
uv venv
uv pip install -r requirements-dev.txt
.venv/bin/alembic upgrade head
.venv/bin/uvicorn app.main:app --reload
```

Runtime memakai versi pada `backend/requirements.lock`. `AUTO_CREATE_TABLES` hanya dipakai tes/dev; migrasi adalah jalur runtime normal. `RATE_LIMIT_STORAGE_URI=memory://` membatasi login per proses. Untuk beberapa worker/replica, gunakan Redis bersama, misalnya URI Redis dari environment deployment.

## Seller

```bash
cd apps/seller
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

Tersedia entry point dan native flavor/scheme `dev`, `staging`, `prod`. Base URL berasal dari `.env.<flavor>.example` melalui dotenv. Contoh dev menggunakan alamat host Android emulator; contoh staging/prod memakai domain contoh dan perlu diganti saat digunakan.

Untuk HP fisik atau server lain, berikan alamat API yang dapat dijangkau perangkat:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_BASE_URL=https://api-anda.example.com
```

Token akses/refresh disimpan sebagai satu sesi di `flutter_secure_storage`. Onboarding hanya muncul otomatis sebelum tombol Lanjut pertama kali ditekan. Register menyimpan kategori, metode kirim dan radius ke backend. Beranda menampilkan status toko dan stok menipis dari produk sendiri; statistik transaksi tetap nol, banner pesan A2 membuka tab Pesanan. Produk mendukung tambah/foto/edit/hapus, pencarian, kategori dan toggle tersedia. Menu Toko menyimpan profil, tujuh hari jam buka, pengiriman dan rekening. Status buka/tutup diubah manual. Apple dan lupa kata sandi menampilkan "Segera hadir"; upload logo belum termasuk kontrak A2.

Pesanan mempunyai tab Baru, Diproses dan Selesai, detail timeline, terima, penolakan dengan alasan, serta perubahan status sampai Tiba. Urungkan tersedia sebelum 10 detik sejak terima menurut server. Badge dan list diperbarui setelah mutasi. Customer dummy null ditampilkan sebagai `-` dan telepon nonaktif. Nama/harga item tetap tersimpan ketika produk diubah atau dihapus. Checkout, pengurangan stok dan pembayaran belum dikerjakan.

Google login membutuhkan `GOOGLE_CLIENT_ID` di backend dan seller serta konfigurasi OAuth/signing Android/iOS. ID yang diverifikasi backend adalah audience server. Bila belum dikonfigurasi, app menampilkan pesan yang jelas. Jangan memasukkan client secret atau API key ke asset Flutter. Pengujian akun Google nyata dan build/signing iOS masih memerlukan konfigurasi pemilik dan macOS.

## Pemeriksaan

```bash
cd backend
.venv/bin/python -m pytest -q
.venv/bin/ruff check .
.venv/bin/python -c "import app.main"
```

```bash
cd packages/shared
flutter analyze
flutter test
```

```bash
cd apps/seller
flutter analyze
flutter test
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter drive --driver=test_driver/a2.dart --target=integration_test/a2_test.dart --flavor dev -d emulator-5554 --keep-app-running
flutter drive --driver=test_driver/a3.dart --target=integration_test/a3_test.dart --flavor dev -d emulator-5554 --keep-app-running
```

Tes integrasi A2 menghapus secure storage app dev untuk memulai dari onboarding. Jalankan pada emulator/perangkat pengujian dengan backend aktif. Tes membuat akun, menyimpan kategori/pengiriman, profil, jam, produk/foto, toggle, logout/login dan memeriksa pemulihan sesi. Picker pada tes memakai gambar fixture; upload dan API memakai backend nyata. Screenshot hasil berada di `artifacts/a2/`. Setelah `flutter drive`, build dan install APK dengan entry point `lib/main_dev.dart` untuk penggunaan normal.

Tes integrasi A3 juga menghapus secure storage app dev, membuat akun/produk/tiga pesanan lewat API dev, lalu memeriksa penolakan, Urungkan, tahap Dikemas/Diantar/Selesai, empty state, badge dan pemulihan sesi. Backend harus `ENV=dev`. Screenshot hasil berada di `artifacts/a3/`. Build APK normal dengan perintah di atas sesudah tes perangkat.

Tes PostgreSQL membutuhkan `A2_TEST_POSTGRES_URL` pada environment backend; tanpa itu tes yang memerlukannya dilewati. Gunakan database pengujian. Fixture membuat schema unik dan menghapus schema uji miliknya setelah selesai. Tes mencakup konflik upload/delete A2, snapshot sesudah hapus produk, timezone, accept/reject dan undo/dikemas bersamaan. Tes migrasi memakai database SQLite sementara untuk memeriksa backfill A1 dan mempertahankan data A2. Migrasi juga diperiksa pada PostgreSQL lokal.

`integration_test/auth_test.dart` adalah bukti alur A1 dengan Beranda placeholder lama. Assertion layarnya dipertahankan sebagai catatan fase; alur perangkat aktif adalah `a2_test.dart` dan `a3_test.dart`. Tes widget A2 untuk placeholder dipindahkan dari Pesanan A3 ke Laporan A4 sesuai kontrak baru; Pesanan kini mempunyai delapan tes widget tersendiri.

Dari root proyek, acceptance lewat curl dijalankan tanpa mencetak password/token:

```bash
python3 scripts/smoke_auth.py --base-url http://127.0.0.1:8000
python3 scripts/smoke_store.py --base-url http://127.0.0.1:8000
python3 scripts/smoke_pesanan.py --base-url http://127.0.0.1:8000
docker compose config --quiet
```

Contoh curl ada di `A1_API.md`, `A2_API.md` dan `A3_API.md`. Status verifikasi aktual dan pekerjaan berikutnya ada di `handoff.md`.

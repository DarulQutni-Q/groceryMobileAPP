# Daclanari Grocery, Fase A1

Fase ini mencakup akun seller dan backend. Customer belum diinisialisasi. UI mengacu pada gambar di `docs/screenshots/seller/`; kolom Email tambahan pada login dan daftar sudah disetujui.

## Backend

Salin contoh environment, lalu isi password database dan JWT secret minimal 32 karakter. Jangan memakai `CHANGE_ME`. Contoh tidak berisi kredensial nyata.

```bash
cp .env.example .env
docker compose up --build -d
curl --fail http://localhost:8000/health
```

Container menjalankan `alembic upgrade head` sebelum Uvicorn. PostgreSQL ada di localhost:55432; API ada di localhost:8000. Port ini hanya di-bind ke loopback host. `GET /health` memeriksa koneksi database.

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

Token akses/refresh disimpan sebagai satu sesi di `flutter_secure_storage`. Onboarding hanya muncul otomatis sebelum tombol Lanjut pertama kali ditekan. Register tahap kategori dan pengiriman hanya disimpan di state lokal. Beranda masih placeholder. Apple dan lupa kata sandi menampilkan "Segera hadir".

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
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_test.dart --flavor dev -d emulator-5554
```

Tes integrasi menghapus data secure storage app dev untuk memulai dari onboarding. Jalankan pada emulator/perangkat pengujian. Screenshot hasil disimpan di `artifacts/a1/` pada root proyek. Tes ini membuat akun uji di backend, tidak mengirim kategori/pengiriman ke server, dan memeriksa pemulihan sesi dengan membuat ulang app.

Dari root proyek, acceptance lewat curl dijalankan tanpa mencetak password/token:

```bash
python3 scripts/smoke_auth.py --base-url http://127.0.0.1:8000
docker compose config --quiet
```

Contoh curl untuk semua endpoint ada di `A1_API.md`. Status verifikasi aktual dan pekerjaan berikutnya ada di `handoff.md`.

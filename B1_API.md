# B1: auth customer GardenMart

Form Daftar sekarang meminta email, nomor HP, kata sandi dan konfirmasi.
HP wajib di UI sesuai pilihan pengguna. Setelah berhasil, Home menampilkan
`Selamat pagi, nama`. Nama berasal dari bagian email sebelum @.

## Pilihan login HP

Pakai satu endpoint baru, `POST /auth/login/phone`, dengan kolom User.phone
nyata. Tidak membuat email sintetis. Input 0812..., 62812..., +62812... atau
812... dinormalisasi menjadi +62812... untuk customer. Nomor duplikat ditolak.
Email asli tetap menjadi identitas unik backend. Login email customer memakai
`POST /auth/login` dengan role customer; request seller lama tetap default seller.

Tidak ada model atau migrasi baru. Customer tidak mendapat Toko atau JamBuka.
Google dapat membuat customer tanpa HP; login Google tetap memakai akun Google.
Role admin ditolak 422. Role akun yang sudah ada tidak diganti saat login Google.

## Perubahan per file

| File | Perubahan dan alasan |
| --- | --- |
| backend/app/schemas/auth.py | Role seller/customer, nama toko wajib hanya seller, schema login HP dan normalisasi nomor |
| backend/app/services/auth.py | Register dan Google mengikuti role; lookup HP hanya customer; customer tidak membuat toko |
| backend/app/core/security.py | get_authenticated_user menerima dua role; get_current_user tetap khusus seller untuk seluruh fitur toko |
| backend/app/routers/auth.py | Endpoint login HP; me/refresh/fcm menerima sesi customer; login email/Google menerima role |
| backend/tests/test_customer_auth.py | Register, phone, refresh, Google, admin, unique phone dan isolasi seller di SQLite/PostgreSQL |
| backend/tests/test_auth.py | Tambah assertion admin422, pertahankan assertion default seller dan unique phone |
| packages/shared/lib/src/api/auth_api.dart | registerCustomer/loginCustomer, Google role opsional dan request reset tanpa menduplikasi client |
| packages/shared/lib/src/core/secure_storage.dart | Preferensi Ingat Saya memakai antrean penyimpanan terenkripsi yang sama |
| packages/shared/test/customer_auth_api_test.dart | Kontrak payload customer, kompatibilitas seller dan preferensi sesi |
| apps/customer/lib/bootstrap.dart dan main*.dart | Env/dart-define dev, staging, prod; staging/prod wajib URL HTTPS |
| apps/customer/lib/features/auth/application/auth_provider.dart | Riverpod login/register/Google/logout/restore; cegah hasil request lama menghidupkan sesi setelah logout |
| apps/customer/lib/app.dart dan core/theme.dart | Rute auth, Home placeholder, snackbar merah, palet acuan dan Material3 |
| apps/customer/lib/features/auth/presentation/ | Splash, login, daftar + HP, reset, email terkirim, eye toggle, validasi dan layout yang dapat digulir |
| apps/customer/assets/ dan pubspec.yaml | Ilustrasi/logo dari acuan, font Liberation Serif beserta lisensi; dependensi yang sama dengan pola seller |
| apps/customer/android/ dan ios/ | Scaffold customer dan tiga flavor; HTTP lokal hanya Android dev |
| apps/customer/test/ | Tes sesi, race logout, remember, validasi HP/password, snackbar, navigasi, pembuka email dan layar kecil |
| apps/customer/integration_test/auth_test.dart dan test_driver/ | Journey UI ke backend lokal dan screenshot |
| B1_PLAN.md, artifacts/b1/, handoff.md, MISTAKES.md | Keputusan, hasil pemeriksaan dan batas verifikasi |

Tidak mengedit apps/seller. Diff seller_shell.dart yang sudah ada sebelum B1
milik pengguna dan tetap dipertahankan. Perubahan root/A3 yang sudah ada juga
terpisah dari pekerjaan B1. Audience JWT lama dipertahankan untuk kompatibilitas;
penentuan akses memakai role User di DB.

## Jalankan customer

Dari apps/customer:

```sh
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart --dart-define=API_BASE_URL="$STAGING_API_URL"
flutter run --flavor prod -t lib/main_prod.dart --dart-define=API_BASE_URL="$PROD_API_URL"
```

API dev: http://10.0.2.2:8000 untuk emulator Android. URL staging/prod kosong
sampai diisi operator. GOOGLE_CLIENT_ID dapat diisi lewat dart-define yang sama.
Client OAuth/signing perangkat dan server audience harus benar untuk login akun
Google sungguhan. Tidak menaruh secret di env contoh.

## Contoh curl

Contoh di bawah memakai API lokal. Isi EMAIL, PHONE, PASSWORD, ACCESS_TOKEN,
REFRESH_TOKEN dan GOOGLE_ID_TOKEN sendiri. Jangan menempel token ke dokumentasi.
`umask 077` menjaga file respons sesi hanya terbaca pemilik.

```sh
umask 077
API_BASE_URL=http://127.0.0.1:8000
curl -sS "$API_BASE_URL/auth/register" -H 'Content-Type: application/json' \
  -d "{\"role\":\"customer\",\"email\":\"$EMAIL\",\"phone\":\"$PHONE\",\"password\":\"$PASSWORD\"}" -o /tmp/gardenmart-register.json
curl -sS "$API_BASE_URL/auth/login/phone" -H 'Content-Type: application/json' \
  -d "{\"phone\":\"$PHONE\",\"password\":\"$PASSWORD\"}" -o /tmp/gardenmart-login.json
curl -sS "$API_BASE_URL/auth/login" -H 'Content-Type: application/json' \
  -d "{\"role\":\"customer\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" -o /tmp/gardenmart-email-login.json
curl -sS "$API_BASE_URL/auth/google" -H 'Content-Type: application/json' \
  -d "{\"role\":\"customer\",\"id_token\":\"$GOOGLE_ID_TOKEN\"}" -o /tmp/gardenmart-google.json
curl -sS "$API_BASE_URL/auth/me" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS "$API_BASE_URL/auth/refresh" -H 'Content-Type: application/json' \
  -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}" -o /tmp/gardenmart-refresh.json
curl -sS -X PATCH "$API_BASE_URL/auth/fcm-token" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' \
  -d '{"fcm_token":"token-perangkat-uji"}'
```

## Hasil pemeriksaan 21 Oktober 2026

| Pemeriksaan | Hasil |
| --- | --- |
| Backend pytest SQLite dan PostgreSQL | 150 passed, tanpa skip |
| HTTP API Docker nyata | 19 kasus expected=actual, tidak ada 500 |
| Customer analyze / test | No issues found / 11 passed |
| Shared analyze / test | No issues found / 20 passed |
| Seller analyze / test, tanpa edit source | No issues found / 32 passed |
| APK Android dev | Build/install/run dan force-stop/restart lulus |
| Journey Android dengan backend nyata | Daftar HP, profil, restore sesi, logout dan login HP lulus |
| Layar kecil | 320x568, skala teks1.3, form dapat digulir tanpa overflow |
| Compose config | Valid; backend lokal ENV=dev |
| Review auth read-only | Tidak ada P1/P2 yang dilaporkan pada role, HP atau sesi |

213 tes backend/unit/widget lulus, ditambah satu journey Android. Status 19 kasus
HTTP tersimpan di artifacts/b1/live-http.json; log backend/shared/seller dan
screenshot tersedia di artifacts/b1. Pemeriksaan APK normal setelah force-stop
dicatat terpisah di artifacts/b1/cold-start.txt.

## Batas dan status Git

- Endpoint forgot-password belum ada. Send Email menerima404 dan menampilkan
  Segera hadir, sesuai B1. Email Terkirim hanya dibuka bila API reset sukses;
  screenshot halaman ini dibuat lewat rute preview dalam integration test,
  bukan bukti email sungguhan terkirim. Open My Email terhubung ke url_launcher.
- Apple UI menampilkan Segera hadir. OTP belum diimplementasikan.
- Empat gambar acuan sudah dilihat. Acuan Email Terkirim dan font sumber asli
  tidak tersedia, sehingga tidak mengklaim pixel-identik. Serif berlisensi
  mengikuti bentuk acuan; halaman email memakai ikon Material biru/oranye.
- Akun Google nyata, app email native, perangkat fisik, build/signing iOS dan
  backend staging/prod belum diuji. Scheme iOS diperiksa sebagai XML di Linux.
- SDK XML versi3/4 dan diagnostik frame/IME emulator muncul saat build/run;
  build dan journey tetap lulus. Docker memakai classic builder karena plugin
  buildx tidak tersedia.
- Pengguna telah mengizinkan commit B1 dan commit langsung setiap perubahan
  kecil setelah diverifikasi. Aturan dicatat di AGENTS.md. Backend, shared,
  fondasi customer dan layar auth dikomit terpisah dengan pesan natural.
  artifacts/b1/git-log.txt adalah snapshot sebelum commit bukti pengujian ini.

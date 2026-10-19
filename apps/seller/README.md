# Seller Daclanari Grocery

App Flutter Android/iOS untuk pemilik toko. Fase A1 menyediakan splash, onboarding sekali, login email/Google, register tiga langkah, sesi tersimpan, dan Beranda placeholder.

Jalankan dari folder ini:

```bash
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

Untuk server lain, gunakan `--dart-define=API_BASE_URL=https://alamat-api-anda`. Contoh URL per flavor ada pada `.env.dev.example`, `.env.staging.example`, dan `.env.prod.example`.

Nama aplikasi dev/staging berbeda, dengan suffix ID `.dev`/`.staging`. Prod memakai `com.daclanari.seller`. Scheme iOS tersedia untuk ketiganya, tetapi build dan signing memerlukan macOS/Xcode.

Google perlu client ID dan konfigurasi OAuth platform. Tanpa konfigurasi, app menampilkan pesan yang jelas. Apple dan lupa sandi menampilkan "Segera hadir". Kategori dan pengiriman register hanya state lokal.

Panduan backend, pengujian, dan batas verifikasi ada di README root. Referensi screenshot asli tetap di `docs/screenshots/seller`; salinannya dipakai untuk clipping artwork tanpa mengubah gambar.

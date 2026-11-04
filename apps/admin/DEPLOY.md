# Deploy dashboard admin

Dashboard diserve backend dari `/dashboard` (volume `./apps/admin/build/web:/srv/admin:ro`).

Build HARUS pakai base href subpath, kalau tidak halaman blank putih karena
`flutter_bootstrap.js` mengambil `flutter.js` dan `main.dart.js` dari root (`/`)
yang tidak ada (404), padahal file-nya hanya ada di bawah `/dashboard/`:

```
flutter build web --release --base-href /dashboard/
```

Build tanpa flag ini adalah penyebab insiden blank page 2026-11-04. Setelah
rebuild, cek: `curl` ke `/dashboard/flutter.js` dan `/dashboard/main.dart.js`
harus 200, dan halaman harus dirender di browser sebelum diserahkan ke user.

Tidak perlu restart container setelah rebuild web: volume mount langsung
memantulkan isi `build/web` yang baru. Backend hanya perlu rebuild kalau kode
`backend/` berubah.

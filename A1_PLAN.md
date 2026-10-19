# Fase A1: akun seller

Status: disetujui pengguna pada 19 Oktober 2026. Tambahkan kolom Email pada login dan daftar. Antislop diterapkan saat pengerjaan.

## Sumber

- Attachment Fase A1 `4d47f647-fdff-46f2-a62e-889a6eb81548/pasted-text.txt`.
- `prd.md` bagian 2.1: onboarding sekali, registrasi tiga langkah, jarak antar 1-10 km dengan default 5 km.
- `design.md` bagian 2-4: Material 3, screenshot sebagai acuan visual, model User, backend router/service/model.
- `rules.md`: pesan Indonesia, tanpa em dash, analyze/test/import/Compose wajib diperiksa.
- Screenshot seller menggunakan nama `Pasted image*.png`. Dokumen aktual ada di root; roadmap bertahap belum diberikan, maka cakupan A1 mengikuti attachment.

## Keputusan

- Tidak mengubah `apps/customer` atau dokumen/screenshot sumber.
- Enam endpoint auth seller, shared auth client, splash/onboarding/login/register/sukses, dan Home placeholder.
- Email tetap identitas login backend. Kolom Email tambahan sudah disetujui.
- JWT akses 15 menit dan refresh 7 hari dibedakan melalui jenis token. Token hanya di secure storage.
- Google ID token diverifikasi di server terhadap audience. Konfigurasi yang belum tersedia menghasilkan pesan jelas; tidak menghubungkan akun email yang ada secara otomatis.
- Langkah kedua/ketiga register hanya state lokal.
- Flutter memakai Material 3 dan Riverpod StateNotifier. Ilustrasi dari clipping screenshot sumber, tanpa mengubah gambar asli atau membuat aset pengganti.
- URL API dari environment per flavor. Contoh environment tidak berisi secrets.
- PostgreSQL untuk runtime, SQLite hanya untuk tes HTTP terisolasi. Skema awal menggunakan Alembic.
- Commit kecil hanya berisi hasil A1. Dokumen/screenshot pengguna yang untracked tidak dimasukkan; tidak push tanpa instruksi eksplisit.

## Peta dampak dan seam

| Area | Konsumen produksi | Verifikasi |
| --- | --- | --- |
| Model/schema/security/service | Router auth di FastAPI | HTTP register/login/refresh/me/fcm-token/Google, validasi, limit, jenis token |
| DB/settings | FastAPI, migrasi, Compose | Import, migrasi DB nyata, health DB, Compose config |
| Shared API/storage | Auth notifier seller | Tes transport, refresh sekali/serentak, logout |
| Auth notifier | Entry point dan layar seller | Tes sesi awal, login/register/error/logout |
| Layar seller | main dev/staging/prod | Widget test, analyze, run Android, screenshot dan overflow |

Belum ada kode aplikasi lama. Shared dapat dikonsumsi customer nanti, tetapi customer sekarang tidak disentuh.

## Pelaksanaan

1. Skeleton, dependency dan environment contoh minimum.
2. Tes HTTP register gagal lebih dulu, lalu implementasi. Lanjut per perilaku untuk login, JWT, refresh, Google, me, dan fcm-token.
3. Tes shared client/notifier, implementasi, lalu layar seller dari screenshot.
4. Acceptance curl tanpa mencetak token/password, analyze/test, migrasi/Compose, build/run dan screenshot.
5. Review independen keamanan/reachability, perbaiki temuan, simpan handoff dan bukti.

## Batas verifikasi

- Google nyata membutuhkan client ID dan konfigurasi OAuth pemilik.
- Build/signing iOS perlu macOS dan Xcode; host saat ini Linux.
- HP fisik belum tersedia; gunakan emulator Android jika dapat dijalankan.
- Bukti screenshot tidak menjadi klaim pixel-perfect tanpa perbandingan.

# Handoff Fase A1

## Cakupan dan keputusan

Fokus seller, shared auth, dan backend. Customer tidak diubah. Pengguna menyetujui penambahan Email pada login/daftar serta antislop selama pengerjaan. Dokumen sumber tetap di root; roadmap bertahap belum diberikan. Batas fase mengikuti attachment A1, bukan cakupan OTP/customer/Home penuh pada plan lama.

## Yang sudah berjalan

- Backend register/login/Google/refresh/me/fcm-token, User UUID, bcrypt, JWT akses 15 menit dan refresh 7 hari, rate limit lima login per menit per IP, pesan validasi Indonesia, CORS allowlist dan health database.
- Identitas Google memakai audience dan subject terverifikasi; email yang sudah ada tidak ditautkan otomatis. Pengujian Google positif memakai mock pada library verifikasi eksternal, bukan akun Google nyata.
- Client Dio menggabungkan refresh serentak, mengulang maksimal sekali, dan mengisolasi request/callback dari sesi lama. Storage dapat pulih setelah operasi gagal.
- Seller splash, onboarding sekali, login, register Akun/Info Toko/Pengiriman/sukses, dan Beranda placeholder. Kategori/pengiriman tidak dikirim ke backend. Apple/lupa sandi hanya snackbar.
- Native flavor/scheme dev/staging/prod dan environment contoh tanpa secrets. APK Android dev berhasil dibangun. Build memakai SDK dari `android/local.properties`, yaitu `/opt/android-sdk` pada host verifikasi.

## Hasil verifikasi pada 20 Oktober 2026

| Pemeriksaan | Hasil |
| --- | --- |
| Backend pytest dengan dependency terkunci | 17 passed |
| Ruff backend | Lulus |
| Import `app.main` | Lulus tanpa membuat koneksi saat import |
| Acceptance curl terhadap Docker/PostgreSQL | Lulus; bukti `artifacts/a1/backend-smoke.txt` |
| Health saat database dihentikan | 503; database kemudian dijalankan kembali |
| Compose config | Valid |
| Alembic current/check di PostgreSQL | `0001_user (head)`, tidak ada perubahan skema tertunda |
| Shared Flutter test | 7 passed |
| Shared Flutter analyze | No issues found |
| Seller Flutter test | 3 passed, termasuk viewport 320x568 dan keyboard |
| Seller Flutter analyze | No issues found |
| Android integration test | Lulus: daftar, kategori/pengiriman, Beranda, logout, login ulang, rekreasi app dengan sesi tersimpan, Google belum dikonfigurasi |
| APK dev entry point normal | Build berhasil setelah tes integrasi |
| Cold start proses Android | Lulus pada APK normal: force-stop, buka ulang, langsung Beranda; bukti `artifacts/a1/cold-start.txt` dan `09-cold-start.png` |

Screenshot tujuh layar utama, opsi login saat scroll, Beranda, dan cold start tersimpan di `artifacts/a1/`. Indeksnya ada di `artifacts/a1/README.md`. Pengambilan menunggu aset/frame selesai agar tidak menyimpan frame transisi. Gambar asli dan salinan artwork dibandingkan byte-per-byte, tetap sama.

## Gap yang tetap terbuka

- Login Google memakai akun nyata belum diuji, membutuhkan OAuth client ID dan signing yang benar.
- Build, signing, dan run iOS belum diuji pada Linux. Scheme hanya diperiksa secara statis.
- Build staging/prod belum dijalankan; konfigurasi ada. HP fisik dan performa produksi belum diuji.
- UI mengikuti warna, artwork dan alur referensi, tetapi belum pixel-identik: latar dekoratif, clipping artwork, dan beberapa spacing/ukuran teks masih berbeda. Tambahan Email sudah disetujui; langkah Info Toko mengikuti request A1 yang hanya meminta kategori, berbeda dari gambar yang juga berisi form akun.
- Aset yang diberikan hanya screenshot dengan frame perangkat, bukan logo/ilustrasi transparan atau font sumber. Salinannya dirender melalui clipping, tanpa mengubah file asli.
- Logout A1 menghapus sesi perangkat; token refresh lama masih berlaku sampai kedaluwarsa. Revokasi server belum termasuk cakupan ini.
- Emulator menampilkan diagnostik frame/IME sistem saat pengetikan; tidak ada exception Flutter/overflow pada tes yang lulus. Performa di HP fisik belum diukur.

## Lingkungan yang ditinggalkan

- Container Compose project `grocery-a1` dan emulator pengujian sedang berjalan. PostgreSQL/HTTP hanya dibuka pada loopback host.
- Kredensial uji acak disimpan sementara di `/tmp/grocery-a1-20261020-env.json` dengan mode 0600; tidak dicetak atau dikomit. Tidak membuat `.env` nyata di proyek.
- Jika membuat environment pengembangan sendiri dengan password lain, hentikan container uji dan gunakan project/volume terpisah, misalnya `docker compose -p grocery-dev up --build -d`. Volume uji lama memiliki password awalnya sendiri; tidak menimpa/menghapusnya otomatis.
- Dokumen/screenshot sumber milik pengguna tetap untracked sesuai keadaan awal. Commit tidak memasukkan dokumen sumber tersebut. Hasil A1 telah dipush ke GitHub `main` pada commit penggabungan `d913baf`; commit LICENSE awal remote ikut dipertahankan. Remote memakai HTTPS sesuai autentikasi GitHub CLI yang aktif.

## Berikutnya

1. Review screenshot dan tutup selisih visual terhadap Figma sebelum menyebut UI final/pixel-identik.
2. Lengkapi OAuth Google dan verifikasi dengan akun nyata; uji iOS pada macOS.
3. Permintaan A2 sudah diterima, tetapi terpotong pada "Varian tutup: kalau stat". Draft dan keputusan yang belum disepakati ada di `A2_PLAN.md`. Kode fitur/migrasi A2 belum diterapkan. Beranda lengkap, produk, pembayaran, OTP dan customer belum dikerjakan.
4. Gunakan task baru untuk fase berikutnya dengan merujuk file ini agar konteks tetap ringkas.

Panduan menjalankan: `README.md`. Daftar endpoint dan curl: `A1_API.md`. Keputusan: `A1_PLAN.md`. Riwayat perbaikan kerja: `MISTAKES.md`.

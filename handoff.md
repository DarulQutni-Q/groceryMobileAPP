# Handoff Fase A2

## Keputusan dan cakupan

Pengguna meminta A2 lengkap lebih dahulu, A3 nanti. Seller, shared dan backend sudah terhubung untuk Beranda, Produk dan Toko. Customer tidak diubah. Rekomendasi A2 dan pengecualian Urungkan A3 sudah disetujui; jangan meminta persetujuan ulang untuk hal yang sama. Rancangan A3 tetap di `A3_PLAN.md`, tanpa implementasi pesanan.

Dokumen sumber aktual ada di root: `prd.md`, `design.md`, `rules.md`, `plan.md`. `docs/ROADMAP_BERTAHAP.md` belum tersedia. Gambar A2 memakai nama `Pasted image (4)-(9), (12)-(14), (21)-(22).png` di `docs/screenshots/seller/`. Sumber milik pengguna tetap untracked seperti keadaan awal.

## Yang sudah berjalan

- Backend A1 tetap aktif. Akun seller baru dan Toko dibuat satu transaksi. Migrasi `0002_toko_produk` menambahkan Toko, tujuh JamBuka dan Produk, serta backfill akun A1. Toko satu per seller, awal tutup, radius 5 km; fallback Google `Toko [nama]` maksimal 120 karakter.
- Dua belas endpoint toko/produk: profil, jam tujuh hari, status, CRUD, pencarian/filter, toggle dan foto. Seluruh akses dibatasi toko dari JWT. Validasi harga/stok/satuan/jam memakai pesan Indonesia. Lihat `A2_API.md`.
- Upload memeriksa ekstensi/MIME/decode JPG/PNG/WebP, maksimal 5 MB dan 25 MP. Nama file UUID, rollback membersihkan file baru, penggantian/hapus membersihkan file lama. Row lock melindungi upload versus delete. Volume `uploads_data` mempertahankan file saat recreate container.
- Shared menyediakan model Toko/JamBuka/Produk dan API toko/produk. Retry multipart setelah refresh 401 memakai FormData clone agar stream tidak dipakai ulang.
- Seller mempunyai lima tab. Beranda menghitung stok <= 5 dari seluruh produk sendiri; transaksi tetap nol. Produk mendukung foto galeri/kamera, create/edit/delete, search, kategori dan toggle. Toko menyimpan profil, tujuh hari jam, pengiriman/radius dan rekening. Jadwal tidak otomatis mengubah status toko.
- Registrasi A2 menyimpan kategori/pengiriman/radius ke backend. Pilihan A1 lama yang hanya lokal tidak dapat dipulihkan; dapat diisi ulang di Toko. State toko dipisahkan per User dan editor ditutup saat sesi berakhir.
- Error logout tetap mempertahankan User agar bisa retry. Mutation yang sudah berhasil tetap dianggap sukses saat refresh gagal; error refresh tampil pada banner Coba lagi. Penghapusan gagal menampilkan pesan di editor.

## Bukti verifikasi 20 Oktober 2026

| Pemeriksaan | Hasil |
| --- | --- |
| Backend pytest | 27 passed, termasuk konflik HTTP upload/delete pada PostgreSQL terisolasi |
| Backend ruff dan import | Lulus |
| Shared Flutter test / analyze | 9 passed / No issues found |
| Seller Flutter test / analyze | 9 passed / No issues found |
| Android integration A2 | Lulus: registrasi, tambah/foto/toggle/search produk, profil/jam/pengiriman/rekening, logout/login dan rekreasi sesi |
| APK dev normal | Build dan install berhasil; force-stop lalu buka ulang langsung Beranda dengan data tersimpan |
| Galeri Android native | Pemilih sistem berhasil mengembalikan gambar dan preview tampil pada form produk APK normal |
| Acceptance curl A2 | Semua lulus; `artifacts/a2/backend-smoke.txt` |
| Compose config | Valid |
| Alembic pada PostgreSQL | `0002_toko_produk (head)`; check tanpa perubahan tertunda |
| Source container | SHA-256 semua file app Python cocok dengan source host yang diuji |
| Foto setelah recreate container | Hash tetap sama, URL tetap dapat dibaca |
| Viewport kecil/keyboard | 320x568 lulus, tanpa overflow Flutter |
| iOS picker config | Info.plist valid; build/run iOS belum diuji |
| Customer | Tidak ada perubahan tracked |

Bukti ada di `artifacts/a2/README.md`, `verification.txt`, `storage-persistence.txt`, `cold-start.txt`, dan screenshot 01-16. Foto pada journey integrasi memakai fixture screenshot login; picker diganti pada tes, seluruh upload dan API berjalan nyata. Galeri native diperiksa terpisah pada APK normal. Tes A1 unit dan HTTP tetap lulus. Skrip perangkat `integration_test/auth_test.dart` masih menyimpan assertion Beranda placeholder A1 sebagai catatan fase; tidak diubah untuk memaksa lulus pada UI A2. Journey perangkat aktif adalah `integration_test/a2_test.dart`.

## Gap yang belum diverifikasi atau belum termasuk kontrak

- UI belum pixel-identik: font sumber tidak tersedia, dekorasi latar dan beberapa ikon/spacing masih berbeda. Field kategori produk ditambahkan sesuai persetujuan; varian tutup memakai empat statistik sesuai kontrak A2. Tidak ada URL/node Figma untuk mengukur token sumber lebih jauh.
- Upload logo Toko tidak mempunyai endpoint pada kontrak A2. Tombol Ubah Foto menjelaskan keadaan ini; foto produk sudah fungsional.
- Kamera native dan pemulihan lost data sesudah Android mematikan proses belum diuji. Build/signing/run iOS, flavor staging/prod, HP fisik dan performa produksi belum diuji. Emulator mengeluarkan diagnostik frame/IME sistem; tidak ada exception Flutter/overflow pada tes yang lulus.
- Login Google akun nyata belum diuji, membutuhkan OAuth/signing. Logout menghapus sesi perangkat; revokasi refresh token server belum termasuk A1/A2.
- Pesanan, pembayaran, laporan nyata, push notification, S3 dan customer belum dikerjakan. Tab Pesanan/Laporan menampilkan A3/A4.

## Lingkungan dan kelanjutan

Compose project `grocery-a1` berjalan, PostgreSQL di loopback 55432 dan HTTP 8000. Emulator `pixel` memakai `emulator-5554`. SDK build berasal dari `/opt/android-sdk` sesuai `apps/seller/android/local.properties`. Kredensial uji acak berada di `/tmp/grocery-a1-20261020-env.json` mode 0600, tidak dikomit/dicetak. Gunakan project/volume terpisah untuk environment sendiri; jangan menimpa password volume yang sudah ada.

Remote memakai HTTPS sesuai autentikasi GitHub CLI aktif. Riwayat LICENSE remote dan hasil A1 dipertahankan saat merge. Lihat log Git untuk commit A2 dan status push terbaru.

A3 berikutnya mengikuti `A3_PLAN.md` dan lampiran lengkap `9120f74a-43ea-43b4-9bc9-46104eab4915/pasted-text.txt`. Mulai task baru dengan file handoff ini agar konteks tetap ringkas. Jangan sentuh customer. Panduan run/test ada di `README.md`; curl ada di `A1_API.md` dan `A2_API.md`; keputusan A2 ada di `A2_PLAN.md`.

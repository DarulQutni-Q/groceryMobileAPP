# Handoff Fase A3

## Cakupan dan keputusan

A2 selesai dan dipush pada b876f2b. Pengguna kemudian meminta melanjutkan seluruh A3 melalui lampiran `a191e541-deac-4103-bc42-e83cad9d577d/pasted-text.txt`. Seller, shared dan backend kini terhubung untuk pesanan. Customer tidak diubah. Laporan tetap placeholder A4; pembayaran dan push belum dikerjakan. Jangan meminta persetujuan ulang untuk cakupan dan pengecualian Urungkan yang sudah disetujui.

Sumber aktual ada di root: `prd.md`, `design.md`, `rules.md`, `plan.md`. `docs/ROADMAP_BERTAHAP.md` belum tersedia. Sumber pengguna tetap untracked seperti keadaan awal. Acuan A3 tersedia sebagai `Pasted image (11).png` dan `Pasted image (17).png`; nama kanonis 05/06 serta referensi detail dan varian lainnya tidak tersedia.

## Yang sudah berjalan

- Fondasi A1/A2 tetap berjalan: akun, Toko, tujuh JamBuka, Produk, foto lokal dan lima tab. Rincian kontrak ada di `A1_API.md`, `A2_API.md` dan bukti historis `artifacts/a2/`.
- Migrasi `0003_pesanan` menambah Pesanan/PesananItem tanpa mengganti data A2. Kode DG lima digit unik memakai retry terbatas; nama/harga snapshot dan total dihitung server. Setelah produk dihapus, FK item null tetapi snapshot/riwayat tetap ada.
- Tujuh endpoint pesanan mencakup list/filter/detail, terima, tolak wajib alasan, status, Urungkan dan dummy dev. Semua akses dibatasi Toko pemilik JWT. Transisi/deadline di bawah row lock PostgreSQL. Lompatan, mundur dan terminal menghasilkan 400. Alasan kosong/spasi menghasilkan 422.
- Urungkan hanya dari Diproses sebelum 10 detik sejak terima menurut server. Response mengirim accepted_at, undo_until dan server_time UTC; UI mengurangi latensi request dari jendela tampilannya.
- ENV backend default prod. Endpoint dummy hanya menerima ENV=dev, termasuk tetap wajib JWT. Guard prod/staging/kosong/default menghasilkan 404 tanpa menulis pesanan. Dummy memakai produk toko sendiri dan customer null; tidak menjalankan checkout/pemotongan stok.
- Shared menyediakan Pesanan/PesananItem dan PesananApi dengan list/detail/terima/tolak/status/urungkan. Client tetap memakai refresh JWT A1.
- Tab Pesanan mempunyai tiga tab, count, status, kartu, tanggal/jam, item/slot/total, empty dan error/retry. Detail menyediakan timeline, alamat, snapshot, rincian biaya, terima, tolak dan perubahan tahap sampai selesai. Customer null tampil `-` dan telepon nonaktif. Lainnya mewajibkan teks. Sheet terima hijau mempunyai countdown/Urungkan.
- Riverpod terpisah per user dan detail per ID. Hasil request lama tidak mengganti state baru. Mutasi memperbarui list/count segera; refresh gagal dilaporkan. Tes regresi melindungi lifecycle saat undo selesai setelah route ditutup dan kegagalan refresh detail.
- Statistik transaksi Beranda masih nol dan banner pesan tetap placeholder A2; tombolnya membuka Pesanan. Jadwal toko tetap manual. Upload logo, pembayaran, laporan dan push tidak ditambahkan.

## Verifikasi 20 Oktober 2026

| Pemeriksaan | Hasil |
| --- | --- |
| Backend pytest | 41 passed, tanpa skip, termasuk PostgreSQL nyata |
| Backend ruff / import | Lulus |
| Shared test / analyze | 10 passed / No issues found |
| Seller test / analyze | 17 passed / No issues found |
| Android integration A3 | Lulus: tiga dummy, tolak, Lainnya, terima/undo, Dikemas/Diantar/Selesai, badge, empty dan sesi |
| APK dev normal | Build/install berhasil; force-stop dan buka ulang memulihkan sesi serta tiga riwayat |
| Acceptance curl A3 | Lulus seluruh skenario wajib, ownership dan snapshot |
| ENV prod nyata | Uvicorn image sama dengan ENV=prod: POST dummy 404, jumlah pesanan tetap |
| Migrasi PostgreSQL | 0003_pesanan head, check tanpa operasi tertunda |
| Source container | SHA-256 semua file app Python sama dengan host |
| Compose config | Valid |
| Layar kecil/keyboard | 320x568 lulus tanpa overflow |
| Review independen | Backend dan seller, tidak ada P1/P2 tersisa |
| Customer | Tidak ada perubahan tracked |

Total 68 tes unit/widget/HTTP lulus, ditambah perjalanan Android nyata. Bukti ada di `artifacts/a3/README.md`, `verification.txt`, `runtime-checks.txt`, `prod-guard.txt`, `backend-smoke.txt`, `cold-start.txt`, dan screenshot 01-13. Contoh curl tujuh endpoint ada di `A3_API.md`.

Tes widget placeholder A2 dipindahkan dari Pesanan ke Laporan A4 sesuai kontrak baru, bukan untuk menutupi kegagalan. Pesanan mempunyai delapan tes widget baru. Journey A1 `integration_test/auth_test.dart` tetap menyimpan assertion Beranda placeholder lama, belum diubah dan tidak dijalankan sebagai gate A3. Journey A2 tetap menjadi bukti historis auth/toko/produk; perjalanan perangkat yang diulang pada A3 adalah `integration_test/a3_test.dart`.

## Gap dan batas verifikasi

- UI belum pixel-identik. Font sumber tidak tersedia, serta ikon, kurva dan spacing masih berbeda. Detail, Diproses/Selesai, empty dan sheet terima tidak mempunyai gambar sumber untuk diverifikasi persis. Tidak ada URL/node Figma.
- Build/run/signing iOS, HP fisik, panggilan pembeli nyata, flavor staging/prod dan performa produksi belum diuji. Emulator mengeluarkan diagnostik frame/IME; tes lulus tanpa exception Flutter/overflow.
- Batas A1/A2 tetap: Google akun nyata membutuhkan OAuth/signing; logout menghapus sesi perangkat tanpa revokasi server; kamera native/lost data belum diuji; upload logo belum memiliki endpoint. Bukti galeri native dan persistensi foto tetap di `artifacts/a2/`.
- Belum ada customer, checkout, pengurangan stok transaksional, pembayaran, push, laporan nyata atau S3. Pesanan fase ini hanya dibuat melalui endpoint dev.

## Lingkungan dan kelanjutan

Compose project `grocery-a1` berjalan, PostgreSQL di loopback 55432, API di 8000, backend pengujian secara eksplisit ENV=dev. Emulator pixel memakai emulator-5554. SDK build `/opt/android-sdk` mengikuti `apps/seller/android/local.properties`. Kredensial acak berada di `/tmp/grocery-a1-20261020-env.json` mode 0600, tidak dikomit/dicetak. Jangan menimpa password volume lama. Untuk environment baru, isi contoh env sendiri; default prod menonaktifkan dummy.

Remote HTTPS memakai autentikasi GitHub CLI yang aktif. Riwayat LICENSE dan A1/A2 dipertahankan. Status commit/push akhir lihat Git log dan remote. Aturan proyek meminta commit kecil dalam Bahasa Indonesia.

Jika melanjutkan A4, gunakan task baru dan file ini agar konteks ringkas. Baca lampiran A4 sebelum mengerjakan; jangan menganggap detail laporan sudah ditentukan oleh A3. Customer tetap di luar cakupan.

# Handoff B2 customer, 21 Oktober 2026

B2 selesai lokal: browse/search/filter/pagination, detail produk, keranjang
per akun, qty/pilihan/hapus/subtotal, penyimpanan terenkripsi dan lima tab.
Baca B2_API.md untuk endpoint/curl/per-file/batas; B2_PLAN.md untuk ADR;
artifacts/b2/ untuk hasil246tes,49HTTP tanpa500, journey Android dan4screenshot.

Backend164, shared32, customer18 dan seller32 tes lulus. Analyze tiga paket
bersih. List produk/toko maksimal3query termasuk JWT. Seller legacy tetap
array tanpa pagination dan semua mutasi customer403. Tidak ada migrasi B2.
Review state menutup tiga P2 lewat tes merah-hijau: write cart gagal tidak
meracuni pembacaan token, reload masuk antrean, plus menghitung qty terbaru.
Navigator root menggantikan nested navigator pada builder; system Back diuji.
Tombol hapus search menyinkronkan controller dan query serta diuji Android.
APK dev normal dibuild/install dan login HP lewat UI. Verifikasi native
cold start lintas proses belum tuntas: emulator berulang kali terputus dan
AVD baru tidak memuat APK customer. Jangan mengklaimnya lulus. Persistensi
unit/shared dan rebootstrap journey Android lulus; lanjutkan lintas proses
di emulator stabil atau perangkat fisik.

Keranjang satu toko dengan konfirmasi pergantian; key customer_cart_{user_id}.
Subtotal/Checkout hanya pilihan, badge seluruh qty. Beli Sekarang hanya tambah
lalu cart. Foto kosong memakai fallback, harga coret/diskon tersembunyi karena
belum ada metadata backend, deskripsi -. Poin/barcode/stempel/promo/voucher
hanya demo. Header toko pertama API, bukan hasil GPS. B3 harus validasi ulang
stok/harga di server dan implementasi checkout; belum ada reservasi/payment.

Tidak ada perubahan apps/seller dari task B2. Jangan stage diff pengguna pada
A3_API/A3_PLAN/CONTEXT/README/artifacts/a3/seller_shell.dart atau root specs/docs.
Diff awal tersimpan privat /tmp/b2-preserved-user.patch. Pengguna mengizinkan
commit kecil langsung setelah verifikasi; pesan natural Bahasa Indonesia.

Compose dev API8000/PostgreSQL55432; emulatorpixel5554. Password/JWT pengujian
berada dalam file privat /tmp, jangan dicetak/disalin ke repo. HTTP seed hanya
untuk lokal. PostgreSQL tes memakai schema acak terpisah dari public aplikasi.
Build iOS, perangkat fisik dan deploy staging/prod belum diuji. Acuan visual
tersedia sebagai Pasted image(5)/(6)/(8), bukan nama yang disebut attachment;
roadmap bertahap tidak ditemukan. Tidak mengklaim pixel-identik.
Mulai task baru untuk B3 agar konteks fase berikutnya terpisah.

---

# Handoff B1 customer, 21 Oktober 2026

B1 sudah berjalan lokal, termasuk penambahan field HP pada Daftar yang dipilih
pengguna. Keputusan dan perubahan per file ada di B1_API.md; rencana/ADR ada
di B1_PLAN.md; bukti di artifacts/b1/. Baca bagian ini sebelum catatan A5/A4 lama.

## Kontrak customer

Login memakai User.phone nyata melalui POST /auth/login/phone. Nomor customer
normal +62; email asli tetap disimpan, tidak membuat email sintetis. Daftar UI
mewajibkan email/HP/password/konfirmasi. Backend default role seller tetap
kompatibel, menerima customer dan menolak admin422. Customer tidak membuat toko;
me/refresh/fcm menerima sesi customer dan seluruh fitur toko tetap seller-only.
Tidak ada migrasi atau perubahan model. Jangan mengedit apps/seller untuk B1.

Customer memiliki splash, login, daftar, forgot dan email-sent, Riverpod, Google
SDK, remember, encrypted storage, logout dan Home placeholder. Api URL memakai
env/dart-define per flavor; staging/prod wajib HTTPS dan belum diisi. Android
HTTP hanya dev; iOS mempunyai tiga scheme yang belum dibuild di macOS.

## Bukti terbaru

Backend150, customer11, shared20 dan seller32 tes lulus, analyze tiga package
No issues found. Total213 tes dan satu journey Android nyata lulus. API Docker
19 kasus expected=actual tanpa500, termasuk role admin422, duplicate HP400,
customer tidak bisa toko403 dan login keenam429. Image45 file Python cocok
hash host. Compose valid. Full backend log, tabel HTTP dan screenshot ada di
artifacts/b1. APK dev normal juga dibuild/install ulang, login HP melalui UI,
force-stop PID lama dan proses baru langsung Home; lihat cold-start.txt dan09.

## Batas dan kelanjutan

Forgot endpoint belum ada: UI menampilkan Segera hadir pada404. Screenshot05
adalah preview route dan tes reset sukses memakai adapter, bukan email sungguhan.
Apple/OTP belum diimplementasikan. Google akun nyata, email app native, perangkat
fisik, build/signing iOS dan deploy staging/prod belum diuji. Tidak mengklaim
pixel-identik karena acuan email-sent/font asli tidak tersedia. Acuan tersedia
bernama Pasted image.png dan (2),(3),(4), berbeda dari nama di attachment.

Review auth read-only melaporkan tidak ada P1/P2; percobaan review lanjutan agen
berakhir karena kuota workspace. Visual diperiksa langsung oleh agent utama.
Pengguna kini sudah mengizinkan commit B1 dan commit langsung setiap perubahan
kecil setelah diverifikasi, tanpa menunggu perubahan besar atau konfirmasi lagi.
Aturan tersimpan di AGENTS.md. Pesan commit harus natural Bahasa Indonesia.
Backend/shared/fondasi/UI dikomit terpisah. Jangan stage perubahan pengguna:
root specs/docs, A3/README/CONTEXT dan seller_shell.dart sudah berubah sebelum B1.
artifacts/b1/git-log.txt adalah snapshot sebelum commit bukti pengujian.

Backend Compose lokal ENV=dev, API8000, PostgreSQL55432, emulatorpixel5554.
Kredensial tetap di file privat /tmp yang dirujuk bagian A5, jangan dicetak atau
diganti. Task berikutnya B2 sebaiknya dimulai pada task baru dengan handoff ini.

---

# Handoff Fase A5

## Hasil dan kontrak

Backend A5 sudah diimplementasikan dan diuji. Rincian per file, contoh curl dan
batas cakupan ada di A5_API.md; rencana/ADR ada di A5_PLAN.md; bukti di artifacts/a5/.
Tidak ada Flutter yang diubah dalam fase ini. Perubahan pengguna yang sudah ada
di seller_shell.dart, dokumen A3/root dan specs untracked tetap dipertahankan.

JWT memuat User+toko dalam satu query. List pesanan joinedload items/customer;
detail/mutasi tetap selectinload dan row lock. Pagination eksplisit dengan page
atau per_page menghasilkan data/meta, default1/20 dan clamp100. Request lama
tanpa parameter tetap array lengkap supaya Dio dan statistik Beranda tidak rusak.
Index status pesanan/kategori produk ditambahkan lewat0004_query_indexes; kedua
toko_id dan unique email sudah berindex, tidak diduplikasi.

Login5/menit/IP, register3/menit/IP dan mutasi60/menit/user sudah diuji, termasuk
429 dengan sisa detik. JSON request log dan traceback stderr aktif, default
Uvicorn access log dinonaktifkan agar query rahasia tidak ikut tercetak.
CORS env ketat, docs/internal non-dev404 sebelum parser; health SELECT1 dengan
versi1.0.0 dan DB gagal503. NUL, batas integer/string/telepon/boolean, JSON dalam
dan integer5000digit ditangani tanpa500 pada acceptance.

## Bukti dan batas

138 tes lulus tanpa skip (89.19detik), 369 kasus HTTP expected=actual tanpa500.
Ruff, compile, Compose, migration upgrade/downgrade/check dan dua review lulus.
Docker prod mengulang rate limit, health DB mati, guard404 dan cap100; marker
query/password/JWT tidak masuk log. Hash45file app container sama dengan host.
Container/schema runtime uji dibersihkan; backend utama tetap ENVdev, port8000,
health200, migrationhead0004_query_indexes. Build memakai classic builder karena
plugin buildx tidak tersedia; build image tetap berhasil.

Invoice/webhook Xendit belum ada, sehingga tidak membuat fitur pembayaran baru
dan tidak mengklaim batas invoice/token webhook terverifikasi. Refresh/Google
dan URL foto publik dipertahankan agar Flutter tetap kompatibel. Memory limiter
berlaku pada satu proses yang diuji; Redis aktif multiworker dan deployment
internet belum diuji. Perubahan A5 dibuat dalam commit kecil; push A5 belum dilakukan.

## Masalah tombol Toko

toko_screen.dart menampilkan Chip tanpa callback, sehingga tidak bisa diklik.
PATCH /toko/me/status telah terbukti bisa membuka/menutup toko melalui API.
Perbaikan UI yang disarankan memakai ActionChip dan StoreNotifier.mutate yang
sudah dipakai Beranda, beserta busy/error/refresh dan tes widget. Pertanyaan
pengecualian Flutter masih belum dijawab; jangan menganggap sudah disetujui.
Setelah izin itu jelas, lanjut pada task baru agar konteks perubahan UI terpisah.

## Arsip handoff A4

# Handoff Fase A4

## Hasil dan keputusan

A4 fungsional Android telah diuji. Dua endpoint laporan, shared dan tab Laporan seller berjalan dengan rentang 7/30 hari, grafik, tooltip, ranking dan empty state. Offline/retry, loading maksimal tiga detik, snackbar Indonesia, locale Indonesia, konfirmasi logout dan perlindungan submit ganda sudah dipasang. Customer, checkout, pembayaran dan push tidak diubah.

Laporan hanya menghitung pesanan selesai milik toko pada JWT. Waktu selesai memakai updated_at, kalender WIB termasuk hari ini; pembanding adalah periode sebelumnya sama panjang. Baseline nol menghasilkan 0% dan ada_pembanding=false. Ringkasan memakai satu statement SQL/CTE agar total, count, qty dan harian konsisten pada transaksi serentak. Nilai produk terlaris adalah bruto snapshot harga * qty. Produk dihapus tetap masuk laporan dengan ID/foto null dan nama snapshot. Tidak ada migrasi baru, head tetap 0003_pesanan. Lihat A4_API.md dan A4_PLAN.md.

Beranda memakai GET /pesanan yang sudah ada. Penjualan hari ini dan Produk Terjual menghitung transaksi selesai hari ini menurut WIB; kartu Pesanan menghitung seluruh pesanan toko. Shared Pesanan sekarang menampung updatedAt opsional. Loading/error tidak ditampilkan sebagai nol. Refresh memuat ulang profil, produk dan pesanan. Banner tiga pesan masih contoh A2; kotak surat dan push belum menjadi fitur fase ini.

Review menemukan refresh token dahulu menghapus sesi pada kegagalan jaringan/server. Empat tes reproduksi kini melindungi koneksi putus, timeout, 503 dan replay offline. Penolakan autentikasi definitif tetap mengakhiri sesi; gangguan sementara mempertahankan token. Penjagaan generation A1 tetap berlaku untuk akun yang berganti.

## Bukti

- 58 tes backend lulus tanpa skip, termasuk PostgreSQL nyata; 16 tes shared dan 32 tes seller lulus. Total 106 tes, ditambah tiga perjalanan perangkat A2/A3/A4.
- Analyzer shared/seller No issues found; Ruff, import/compileall, Compose dan migrasi lulus. Sebanyak 39 file source Python container cocok dengan host melalui SHA-256.
- Curl toko kosong menghasilkan nol; tiga pesanan selesai menghasilkan Rp 135.000, sembilan barang dan ranking qty 6/3. Dataset perangkat menghasilkan Rp 275.000, tiga pesanan dan 11 barang.
- Journey A4 mematikan Wi-Fi/data emulator, memeriksa banner offline, memulihkan jaringan dan menekan Coba lagi. Nilai Beranda sesudah pulih diperiksa secara ketat.
- APK normal akhir dibangun. Cold start 21 Oktober memulihkan sesi dan membuka Beranda. Tiga pesanan historis tetap ada; penjualan/qty hari ini nol karena pengujian dilanjutkan pada hari berikutnya. Capture native 28 menampilkan header/pills/lima tab utuh, dan 29 merekam cold start.
- Seluruh bukti, checklist layar dan cara mengulang ada di artifacts/a4/README.md, verification.txt, backend-smoke.txt, device.log dan cold-start.txt.

## Batas yang tetap terbuka

UI belum pixel-identik: font, ikon, kurva dan spacing masih berbeda. Source kanonis 09-laporan.png/04-beranda.png, laporan berdata dan Figma/font tidak tersedia. Gambar pengguna Pasted image (10)/(6) dipakai untuk empty/offline. Beberapa screenshot integration kehilangan layer statis; capture APK normal menampilkan layer tersebut utuh. Ini bukan klaim kesamaan piksel.

iOS, perangkat fisik, signing rilis, OAuth Google akun nyata dan panggilan pembeli nyata belum diuji. Native kamera/lost photo tetap mempunyai batas A2. Video opsional tidak dibuat. Journey auth_test.dart A1 yang memeriksa placeholder lama bukan gate saat ini; A2/A3/A4 dijalankan ulang. Assertion perilaku tidak dilemahkan: interaksi tes mengikuti konfirmasi logout dan label Kembali yang kini Indonesia.

## Lingkungan dan status Git

Repo /home/darulqutni/groceryMobileAPP. Emulator pixel tersedia sebagai emulator-5554, SDK build /opt/android-sdk mengikuti local.properties, Flutter /home/darulqutni/flutter. Compose grocery-a1 melayani API loopback 8000 dan PostgreSQL 55432, ENV dev untuk endpoint dummy. Default konfigurasi tetap prod. Kredensial tidak dicetak/dikomit. Jika layanan berhenti, hidupkan container dengan env yang sudah sesuai volume; jangan menimpa password database.

Commit fitur 79f434f, b559a85, 96d902e dan a63f029 telah dipush ke origin/main; b3ea6e6 menyimpan statistik Beranda. Bukti A4 dicatat dalam commit terpisah. Lihat Git log serta status aktual untuk hasil push akhir, jangan memakai catatan ini sebagai pengganti verifikasi remote.

Perubahan pengguna pada A3_API.md, A3_PLAN.md, CONTEXT.md, README.md, artifacts/a3/README.md dan fallback dead-code SellerShell dipertahankan. Dokumen sumber root dan docs pengguna tetap untracked. Jangan memakai git add . atau restore pada perubahan tersebut.

Untuk fase baru gunakan chat baru dengan handoff ini. Jangan mulai A5 sebelum pengguna memintanya.

---

## Arsip handoff A3

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

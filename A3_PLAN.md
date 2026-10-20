# Rancangan Fase A3

Status: fungsional A3 selesai dan terverifikasi 20 Oktober 2026. Pengguna meminta "continue A3" setelah A2 dipush ke main pada b876f2b. Batas kesamaan visual dicatat di bawah dan di handoff.

## Sumber dan keadaan aktual

- Lampiran A3 `9120f74a-43ea-43b4-9bc9-46104eab4915/pasted-text.txt` sudah dibaca lengkap.
- Lampiran terbaru `a191e541-deac-4103-bc42-e83cad9d577d/pasted-text.txt` dibaca pada awal pengerjaan A3; kontrak pesanan sama dan menjadi sumber aktif.
- `prd.md` bagian 2.4: tab pesanan, detail, timeline Diterima/Dikemas/Diantar/Tiba, penolakan dan konfirmasi terima. `design.md` bagian 3-4: Pesanan dan snapshot item. `rules.md`, `AGENTS.md`, dan `CONTEXT.md` sudah dibaca.
- Fondasi Toko/Produk dan lima tab A2 sudah terverifikasi. Entry point backend `create_app`, metadata Alembic, shared Dio dan `SellerShell` menjadi titik integrasi. Laporan tetap placeholder.
- Dokumen spesifikasi ada di root. `docs/ROADMAP_BERTAHAP.md` belum tersedia.

## Keputusan yang sudah disetujui

1. Kerjakan seluruh A2 dahulu, lalu A3. Detail A2 mengikuti PRD/screenshot dan keputusan pada `A2_PLAN.md`.
2. Tambah `PATCH /pesanan/{id}/urungkan` sebagai pengecualian khusus, hanya saat masih Diproses dan maksimal 10 detik sejak diterima menurut waktu server. Endpoint status biasa tetap tidak menerima perpindahan mundur.

Urutan ini mengikuti jawaban pengguna: "yes, kerjakan ... kerjakan yg A2 dulu baru nanti A3".

## Rekomendasi implementasi minimum

- Toko milik seller dan Produk menjadi fondasi FK/snapshot; tidak mengerjakan aplikasi customer. Akun A1 tetap dapat digunakan. Detail fondasi mengikuti keputusan urutan fase di atas.
- Pesanan memakai UUID, kode unik `DG-` dengan lima digit acak dan retry tabrakan terbatas. Nama dan harga item disalin dari Produk dalam transaksi pembuatan pesanan. Total dihitung server dari snapshot, diskon, ongkir dan biaya layanan.
- Seluruh list/detail/mutasi mengambil toko dari seller JWT. Pesanan seller lain menghasilkan 404. Dummy juga hanya dibuat untuk toko pemanggil.
- `ENV` default `prod`; endpoint dummy hanya aktif pada `ENV=dev` dan tetap membutuhkan login seller. Nondev menghasilkan 404 tanpa menulis data. Jangan mengaktifkan dummy berdasarkan flavor Flutter saja.
- Transisi status dan pemeriksaan deadline Urungkan dijalankan atomik di database. Simpan timestamp penerimaan di server; jangan mempercayai countdown perangkat sebagai otorisasi.
- Penolakan hanya melalui endpoint yang mewajibkan alasan nonkosong; `/status` tidak boleh menjadi jalur pintas tanpa alasan.
- Customer null ditampilkan sebagai `-`; tombol telepon dinonaktifkan. Jangan membuat nama atau nomor pembeli fiktif untuk mengisi UI.
- Riverpod list per tab dan detail per ID memakai shared Dio/JWT A1. Setelah mutasi, perbarui list, detail dan badge. Batalkan pengaruh hasil request lama saat logout/pergantian akun.

## Tabel status yang diusulkan

| Status asal | Operasi | Status tujuan |
| --- | --- | --- |
| baru | Terima | diproses |
| baru | Tolak dengan alasan | ditolak |
| diproses | Tandai siap diantar | dikemas |
| dikemas | Update status satu tahap | diantar |
| diantar | Update status satu tahap | selesai |
| baru/diproses/dikemas/diantar | Batalkan | dibatalkan |
| diproses | Urungkan sebelum deadline, jika disetujui | baru |
| selesai/dibatalkan/ditolak | Semua perubahan lanjutan | Ditolak |

Filter tab: Baru hanya `baru`; Diproses mencakup `diproses/dikemas/diantar`; Selesai mencakup `selesai/dibatalkan/ditolak`. Nilai status asli tetap dikirim pada setiap pesanan. Lompatan seperti baru langsung selesai menghasilkan 400.

## Referensi visual dan batasnya

- Daftar Baru: `docs/screenshots/seller/Pasted image (11).png`. Tab `#83AC9E`, badge Baru `#E7B928`, kartu putih dengan strip `#DCCCAC` dan outline tipis, bottom nav tetap.
- Modal tolak: `docs/screenshots/seller/Pasted image (17).png`. Opsi `#ECE5D0`, aksi tolak `#DC043A`, sheet membulat dengan handle `#CDD4C7`.
- Nama kanonis `05-pesanan.png` dan `06-order-detail.png` tidak ada. Screenshot detail, Diproses/Selesai, empty, dan sheet terima belum tersedia. Gaya mengikuti dua acuan yang ada serta teks A3, tetapi kesamaan persis untuk layar tanpa referensi tidak dapat diverifikasi.
- Gambar daftar Baru menampilkan tombol Tandai siap diantar. Ikuti aturan A3 yang lebih spesifik: tombol itu hanya pada Diproses. Radio dan field Lainnya mengikuti permintaan A3 walaupun tidak tergambar pada modal.
- Gunakan komponen Material 3: navigation, tabs, card, dialog/sheet, radio, text field dan buttons. Tidak menggambar komponen dasar sendiri.

## Peta dampak dan pengujian

| Area | Pemanggil/konsumen | Seam verifikasi |
| --- | --- | --- |
| Fondasi Toko/Produk dan migrasi | Auth/register, FK Pesanan | Migrasi PostgreSQL dari A1, akun lama tetap login, isolasi toko |
| Pesanan/model/service | Router JWT | HTTP pembuatan dummy, list/detail, snapshot dan total |
| State machine/deadline | Terima/tolak/status/urungkan | Langkah sah, lompat/mundur/terminal ditolak, alasan kosong/spasi 422, batas waktu server |
| Konkurensi | Transaksi PostgreSQL | Dua mutasi bersamaan tidak menimpa transisi yang sudah berubah |
| ENV | Router internal | Dev berhasil; prod/staging/tidak diisi 404 tanpa data baru |
| Shared API/model | Riverpod seller | Parsing item/status/tanggal, refresh auth A1, error Indonesia |
| Navigasi/list/detail | AuthFlow, lima tab | Tab dan badge sinkron, aksi kartu/detail, empty/error/retry, isolasi sesi |
| Modal dan sheet | Aksi terima/tolak | Pilih alasan/Lainnya, submit, countdown/Urungkan, layar kecil dan keyboard |

Implementasi memakai siklus satu tes HTTP/widget gagal lalu kode minimum sampai lulus per perilaku. Setelah itu jalankan seluruh regresi A1, analyzer/lint/build/import/Compose, acceptance curl, run Android, dan screenshot tiga tab/detail/modal/sheet. Tes PostgreSQL nyata diperlukan karena SQLite tidak membuktikan row locking.

Push notification, pembayaran, checkout/stok transaksional, laporan nyata dan customer app tetap di luar cakupan. Tes lama tidak dilonggarkan untuk menutupi regresi. ENERGY 1 / RHYTHM 1 / MOTION 1 mengikuti referensi operasional: kartu berulang agar pesanan mudah dibandingkan; warna membedakan status; animasi hanya transisi Material.

## Hasil pelaksanaan

- Model, migrasi 0003, tujuh endpoint, shared API/model, Riverpod dan UI pesanan sudah terhubung melalui entry point produksi.
- 41 tes backend, 10 shared dan 17 seller lulus; analyzer shared/seller bersih. Tes PostgreSQL nyata membuktikan snapshot setelah hapus produk, UTC dan konflik transisi. Retry kode, biaya invalid dan overflow diuji tanpa data parsial.
- Acceptance curl membuat tiga dummy dan memeriksa skenario wajib. Guard ENV prod diperiksa melalui Uvicorn pada image yang sama: HTTP 404 dan jumlah pesanan tidak berubah.
- Journey Android A3 lulus dan menghasilkan screenshot 01-12. APK normal dibangun/diinstall, force-stop dan buka ulang memulihkan sesi/riwayat, screenshot 13. Alembic head/check, import, ruff dan Compose lulus; source container cocok dengan host.
- Review independen backend/seller tidak menyisakan P1/P2. Temuan refresh/lifecycle diperbaiki dengan tes regresi. Assertion placeholder A2 dipindahkan ke Laporan A4 mengikuti perubahan kontrak; Pesanan diuji terpisah.
- UI belum pixel-identik dan beberapa gambar acuan belum tersedia. Build/run iOS, HP fisik, panggilan pembeli nyata dan APK staging/prod belum diuji.

Rincian endpoint/curl ada di `A3_API.md`; bukti ada di `artifacts/a3/README.md`; kelanjutan ada di `handoff.md`.

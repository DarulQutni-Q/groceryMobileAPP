# Rancangan Fase A3

Status: ditunda sesuai instruksi pengguna, selesaikan A2 lengkap dahulu. Belum ada implementasi A3. Pengguna sudah menyetujui rekomendasi sebelumnya; tidak perlu meminta persetujuan ulang atas keputusan yang sama.

## Sumber dan keadaan aktual

- Lampiran A3 `9120f74a-43ea-43b4-9bc9-46104eab4915/pasted-text.txt` sudah dibaca lengkap.
- `prd.md` bagian 2.4: tab pesanan, detail, timeline Diterima/Dikemas/Diantar/Tiba, penolakan dan konfirmasi terima. `design.md` bagian 3-4: Pesanan dan snapshot item. `rules.md`, `AGENTS.md`, dan `CONTEXT.md` sudah dibaca.
- Fondasi Toko/Produk, navigasi lima tab dan UI A2 sedang diselesaikan. Periksa `handoff.md` untuk hasil aktual sebelum memulai A3. Pesanan dan konfigurasi ENV untuk dummy A3 belum ada.
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

Push notification, pembayaran, checkout/stok transaksional, laporan nyata dan customer app tetap di luar cakupan. Statistik/produk/profil A2 lengkap tidak dilaporkan selesai bila hanya fondasi yang dikerjakan.

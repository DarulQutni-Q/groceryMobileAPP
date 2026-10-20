# Konteks proyek

Daclanari Grocery adalah aplikasi seller untuk pemilik toko kelontong. GardenMart adalah aplikasi customer yang belum dikerjakan. Satu backend FastAPI melayani ekosistem ini. Fase aktif A3, setelah A2 selesai dan dipush.

- User seller adalah akun pemilik. Satu Toko dimiliki satu User, dengan owner unik. `nama_toko` pada User disinkronkan saat profil Toko diubah untuk kompatibilitas respons auth A1.
- Akun dan Toko dibuat atomik setelah registrasi langkah Akun. Pilihan kategori/pengiriman/radius dikirim saat wizard selesai. Pilihan A1 lama yang hanya lokal tidak bisa dipulihkan; profilnya dapat dilengkapi pada menu Toko.
- JamBuka menyimpan tepat tujuh hari unik, waktu lokal tanpa offset; status buka/tutup tetap manual. Toko baru/hasil migrasi berstatus tutup dengan tujuh hari tutup sampai diatur pemilik.
- Produk milik Toko; harga rupiah integer positif, stok integer nonnegatif, satuan kg/pcs/liter. Ketersediaan terpisah dari stok. Stok menipis adalah stok <= 5.
- Foto produk JPEG/PNG/WebP maksimal 5 MB disimpan lokal pada volume Docker; URL relatif di-resolve terhadap origin API. Logo toko belum punya endpoint upload pada A2.
- Beranda, Produk, Pesanan dan Toko fungsional. Laporan masih placeholder A4. Statistik transaksi di Beranda tetap nol; banner tiga pesan adalah placeholder A2 dan membuka tab Pesanan.
- Pesanan milik satu Toko. Item menyimpan nama/harga snapshot; penghapusan Produk mengosongkan FK item tanpa menghapus riwayat. Total server = subtotal - diskon + ongkir + biaya layanan. Dummy A3 tidak mengurangi stok.
- Timeline maju dari Baru, Diproses, Dikemas, Diantar, Selesai. Ditolak dan Dibatalkan juga terminal. Tab Diproses merangkum tiga tahap tengah; tab Selesai merangkum seluruh terminal. Penolakan hanya dari Baru dengan alasan wajib.
- Urungkan adalah pengecualian yang disetujui: hanya Diproses, sebelum 10 detik sejak diterima menurut waktu server. Mutasi memakai row lock PostgreSQL untuk mencegah konflik.
- Dummy dibuat lewat `/pesanan/internal/test`, hanya jika backend `ENV=dev`; default `prod` menghasilkan 404. Customer dummy null, UI memakai `-` dan telepon nonaktif. Tidak membuat data pembeli fiktif.
- Email adalah identitas login. Nama pemilik dan nama toko mengikuti tampilan screenshot; kolom Email tambahan disetujui pengguna.
- Sesi terdiri dari JWT akses 15 menit dan refresh 7 hari. Logout A1 menghapus sesi perangkat, belum mencabut token di server.
- Subject Google menjadi identitas sosial stabil. Akun dengan email sama tidak otomatis digabung.
- Dokumen sumber ada di root: `prd.md`, `design.md`, `rules.md`, `plan.md`. Roadmap bertahap belum tersedia; permintaan fase dan keputusan pada `A2_PLAN.md`/`A3_PLAN.md` menentukan cakupan. Referensi detail pesanan belum tersedia, sehingga kesamaan persis layar tersebut tidak dapat diverifikasi.

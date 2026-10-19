# Konteks proyek

Daclanari Grocery adalah aplikasi seller untuk pemilik toko kelontong. GardenMart adalah aplikasi customer yang belum dikerjakan pada Fase A1. Satu backend FastAPI melayani ekosistem ini.

- User seller adalah akun pemilik. `nama_toko` pada User dipakai untuk sambutan A1, belum menggantikan model Toko lengkap.
- Akun dibuat setelah registrasi langkah Akun. Info Toko dan Pengiriman pada wizard A1 hanya state lokal, belum menjadi profil toko di database.
- Email adalah identitas login. Nama pemilik dan nama toko mengikuti tampilan screenshot; kolom Email tambahan disetujui pengguna.
- Sesi terdiri dari JWT akses 15 menit dan refresh 7 hari. Logout A1 menghapus sesi perangkat, belum mencabut token di server.
- Subject Google menjadi identitas sosial stabil. Akun dengan email sama tidak otomatis digabung.
- Dokumen sumber ada di root: `prd.md`, `design.md`, `rules.md`, `plan.md`. Roadmap bertahap belum tersedia; attachment A1 menentukan cakupan fase ini.

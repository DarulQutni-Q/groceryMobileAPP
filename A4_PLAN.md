# Rancangan Fase A4

Status: implementasi selesai, verifikasi APK normal dan dokumentasi akhir berjalan. Rekomendasi waktu/perbandingan disampaikan pada klarifikasi, lalu pengguna meminta continue. Implementasi mengikuti rekomendasi tersebut.

## Sumber dan batas cakupan

Lampiran aktif: `7b7a677b-92ef-4bbd-86f9-e81c3edb91c6/pasted-text.txt`. PRD 2.6 mensyaratkan 7/30 Hari, ringkasan, chart, produk terlaris dan empty CTA Lihat Pesanan. PRD 2.3 mensyaratkan banner Tidak ada koneksi internet dan Coba lagi. Baca bersama `design.md` bagian 2/4, `rules.md`, `AGENTS.md` dan handoff A3.

Sumber berada di root, bukan docs; roadmap bertahap belum tersedia. A3 sudah dipush pada 35d4888. Customer, checkout, push dan pembayaran tetap di luar cakupan. Statistik Beranda tidak diperluas dengan endpoint baru di luar kontrak laporan.

## Pohon keputusan

1. Data laporan: hanya pesanan selesai milik Toko dari JWT. Pakai SUM/COUNT/GROUP BY di SQL, tidak memuat semua order ke Python. Agregat order dipisahkan dari item agar total tidak terduplikasi.
2. Waktu dan pembanding: waktu selesai dari updated_at, kalender WIB termasuk hari ini, 7/30 hari dibanding periode sebelumnya sama panjang. Terminal A3 tidak dapat diubah, sehingga updated_at valid sebagai waktu selesai. Tidak perlu migrasi baru. Baseline nol menghasilkan 0% dengan keterangan Belum ada pembanding.
3. Kosong: jika jumlah pesanan nol, total/qty/count nol dan array harian/terlaris kosong. Jika ada order total nol karena diskon penuh, tetap hasilkan grafik 7/30 hari dan qty. Hari tanpa penjualan diisi nol dari hasil SQL maksimal 30 baris.
4. Ranking: qty terbanyak, tie-break stabil; rupiah = SUM harga_snapshot * qty. Ini nilai bruto item, berbeda dari total pesanan termasuk diskon/ongkir/layanan. Produk aktif dikelompokkan per ID dengan nama/foto saat ini. Produk terhapus tetap dihitung per nama snapshot, foto null. Dua produk terhapus bernama sama tidak dapat dibedakan dengan data A3 yang tersisa.
5. UI laporan: komponen Material 3 dan fl_chart. Ambil enam ranking, tampilkan lima; hasil keenam mengaktifkan Lihat semua dengan snackbar Segera hadir. Provider per user/range, hasil request lama tidak mengganti rentang atau akun baru.
6. Koneksi dan loading: connectivity_plus di seller, cek sebelum request penting serta saat resume; jaringan tersedia tetap harus menangani kegagalan API. GET list/detail berhenti menampilkan spinner selambatnya tiga detik lalu error/retry. Submit menampilkan loading, mencegah Enter ganda dan menonaktifkan aksi saat request berlangsung. Jangan melakukan retry otomatis mutasi yang mungkin sudah berhasil di server.
7. Polish: semua empty list punya ilustrasi, teks dan aksi. Pertahankan refresh Produk/Pesanan dan konfirmasi hapus; tambah konfirmasi Keluar. Seluruh error API menampilkan pesan Indonesia/snackbar merah serta retry pada screen load. Material locale Indonesia untuk label bawaan seperti time picker.
8. Hasil review akhir menemukan angka Beranda masih hardcode A2. Beranda kini memakai GET /pesanan yang sudah ada: Penjualan hari ini dan Produk Terjual hanya dari status selesai dengan updated_at pada kalender WIB hari ini; Pesanan menghitung seluruh pesanan toko. Shared menampung updatedAt opsional untuk kompatibilitas. Loading/error memakai indikator dan .../-, bukan angka nol palsu. Refresh memuat ulang profil, produk dan pesanan. Tidak ada endpoint atau migrasi tambahan.

## Acuan visual

- `docs/screenshots/seller/Pasted image (10).png`: laporan kosong, header, pill, ilustrasi tengah dan CTA. Gambar laporan berdata tidak tersedia; ikuti PRD/lampiran untuk chart dan ranking.
- `docs/screenshots/seller/Pasted image (6).png`: Beranda offline, banner merah, ilustrasi, judul Belum bisa memuat data dan Coba lagi.
- Dasar #FDFFF4, kurva #E3E6D1/#F3F6E3, pill #83AC9E, CTA #7EA895, banner #F86361. Komponen resmi Material; chart dari fl_chart. ENERGY 1 / RHYTHM 1 / MOTION 1 mengikuti antarmuka operasional yang sudah ada.
- Nama kanonis 09-laporan.png/04-beranda.png tidak tersedia. Tidak ada Figma/font sumber. Jangan mengklaim kesamaan pixel untuk layar tanpa sumber.

## Peta dampak dan seam tes

| Area | Pemanggil dan konsumen | Bukti yang diperlukan |
| --- | --- | --- |
| Router/schema/service laporan | create_app, get_store JWT, model Pesanan/Item/Produk | HTTP dua seller, status campuran, tiga order selesai, multi-item, total sama, empty, diskon penuh, batas WIB/range, ranking dan produk dihapus |
| Shared laporan | Export shared, Dio/JWT A1, seller provider | Parsing angka/tanggal/foto null, query range/limit dan error |
| Laporan seller | SellerShell tab 1, provider user/range, chart | 7/30, tooltip rupiah, ranking, empty CTA, error/retry, stale response/akun |
| Koneksi | apiClientProvider seller, home, login, semua simpan | Offline sebelum API, banner/CTA, online retry, timeout tiga detik, tidak mengirim mutasi ganda |
| Polish | AuthFlow/AccountForm, toko, produk, pesanan, jam | Enter saat busy, Batal/Keluar, delete, loading/error/empty, refresh, keyboard 320x568, locale Indonesia |
| Runtime | Compose, Alembic head, APK normal | Import/lint/analyzer/test/build, curl, checklist perangkat dan cold start |

Implementasi per jalur vertikal: tes gagal, kode minimum, tes lulus, lalu regresi. Review read-only backend dan seller sudah memetakan risiko agregat serta celah polish. Minta review akhir setelah implementasi.

## Urutan dan bukti akhir

1. Perbaikan submit/konfirmasi yang terpisah dari keputusan laporan.
2. HTTP laporan dan kontrak shared setelah semantik disepakati.
3. Tab Laporan dan chart, lalu offline/loading/error/empty seluruh seller.
4. Jalankan seluruh tes backend/shared/seller, analyzer, import, ruff, Compose, acceptance curl dan build APK.
5. Buka semua screen checklist lampiran pada emulator: auth, Beranda buka/tutup/offline, Produk semua varian/form, Pesanan tiga tab/detail, Laporan data/empty/7/30, Toko/Info/Jam. Matikan koneksi lalu pulihkan dan Coba lagi.
6. Simpan screenshot laporan data/empty/offline, checklist aktual, endpoint/curl, Git log dan handoff. Commit kecil Bahasa Indonesia dan push sesuai aturan proyek. Pernyataan selesai A4 hanya setelah gate wajib lulus; laporkan batas yang tidak diuji.

Referensi paket yang diperiksa: https://pub.dev/packages/fl_chart dan https://pub.dev/packages/connectivity_plus. Dokumentasi connectivity_plus menegaskan transport tersedia tidak menjamin akses internet; error jaringan tetap ditangani. AGP 9.1/Gradle 9.3.1 saat ini memenuhi kebutuhan Android paket terbaru yang diperiksa.

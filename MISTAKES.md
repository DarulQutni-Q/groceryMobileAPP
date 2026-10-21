# Catatan perbaikan kerja

## 20 Oktober 2026: lokasi SDK saat diagnosis build

- Penyebab: memeriksa `~/Android/Sdk` sebelum membaca `apps/seller/android/local.properties`. Build ternyata menggunakan `/opt/android-sdk`; NDK telah terpasang di sana.
- Dampak: diagnosis unduhan menjadi lebih lama. Source, data customer, dan konfigurasi SDK tidak diubah untuk mengatasi dugaan tersebut.
- Perbaikan: gunakan lokasi SDK dari `local.properties` dan baca hasil terbaru log daemon sebelum menyimpulkan proses masih mengunduh.
- Kejadian: 1. Belum memenuhi ambang tiga kejadian untuk aturan permanen.

## 20 Oktober 2026: konteks patch berubah setelah formatter

- Penyebab: patch mencocokkan bentuk kurung atau pemenggalan baris sebelum formatter, bukan isi file saat ini.
- Dampak: tiga patch ditolak tanpa mengubah file; pekerjaan tertunda, assertion tes tetap utuh.
- Perbaikan permanen: baca ulang blok target setelah formatter dan gunakan nama fungsi atau penanda stabil. Aturan ini dicatat di `AGENTS.md`.

## 20 Oktober 2026: fixture dan sinkronisasi tes perangkat A2

- Penyebab: `XFile.fromData` pada implementasi IO mengambil nama dari path, bukan argumen name. Tes juga mencari teks input yang sudah ada saat request simpan masih berjalan.
- Dampak: perjalanan perangkat berhenti sebelum upload atau membaca data sebelum transaksi selesai. Assertion data tetap dipertahankan; tidak ada data produksi yang diubah untuk meluluskan tes.
- Perbaikan: fixture mempunyai path berekstensi, tunggu editor ditutup sebelum memeriksa API, dan tunggu cache gambar sebelum screenshot. Tes perangkat kemudian lulus sampai pemulihan sesi.
- Kejadian: satu pola setup fixture dan satu pola sinkronisasi route; belum memenuhi ambang tiga kejadian untuk aturan permanen.

## 21 Oktober 2026: membedakan kegagalan jaringan dan sesi ditolak

- Penyebab: handler refresh/replay memperlakukan semua exception sebagai sesi kedaluwarsa.
- Dampak: koneksi putus, timeout atau respons 503 dapat menghapus token dan mengeluarkan seller ketika mencoba memuat ulang data.
- Perbaikan: akhiri sesi hanya untuk penolakan autentikasi definitif atau refresh token yang hilang. Pertahankan token pada kegagalan sementara; empat tes API melindungi refresh offline/timeout/503 dan replay offline, termasuk request berikutnya setelah jaringan pulih.
- Kejadian: satu akar masalah pada shared client. Tidak ada assertion lama yang dilemahkan.

## 21 Oktober 2026: batas validasi dan jalur log A5

- Penyebab: validator NUL awal menelusuri list/dict secara rekursif sebelum tipe field divalidasi. Struktur bertingkat dapat memicu RecursionError. Parser juga tidak selalu menolak JSON dalam dengan status yang sama.
- Dampak: input yang salah tipe berpotensi 500. Perbaikan memakai traversal iteratif dan batas JSON eksplisit 100 tingkat; tes nested field 1000 tingkat dan matriks HTTP tetap mempertahankan assertion awal.
- Penyebab observabilitas: fallback error dikirim di luar CORS dan access log Uvicorn tetap mencetak query meskipun logger JSON sudah menghilangkannya.
- Dampak: browser kehilangan akses ke pesan 503/ID dan query rahasia berpotensi masuk log kedua. Fallback kini melewati CORS; entry point menonaktifkan access log bawaan dan diuji memakai marker buatan.
- Kejadian: satu audit A5 dengan tiga akar masalah berbeda. Belum menjadi aturan permanen tiga kejadian.

## 21 Oktober 2026: fixture async dan ilustrasi B1

- Penyebab: fixture SecureStorage dibuat di setUp di luar zona FakeAsync widget; antrean Future tidak selesai ketika pumpAndSettle memutar waktu virtual.
- Dampak: tes form berhenti pada status loading meskipun state test lulus. Fixture dipindah ke awal callback testWidgets; seluruh assertion perilaku dipertahankan.
- Penyebab visual: potongan dekorasi acuan masih memuat sudut card dan teks lama.
- Perbaikan: gunakan potongan dekorasi bersih yang sudah tersedia dengan transform Flutter. Aset berisi teks lama dihapus; screenshot APK normal diperiksa kembali.
- Kejadian: dua pola berbeda, masing-masing satu akar masalah, belum memenuhi tiga kejadian untuk aturan permanen.

- Pemeriksaan staging B1 menemukan whitespace bawaan pada lisensi font. Hanya whitespace yang dinormalisasi, dengan assertion bahwa seluruh kata lisensi tetap sama; pemeriksaan commit kemudian lulus.

## 21 Oktober 2026: whitespace file baru saat commit B1

- Penyebab: pemeriksaan diff sebelum staging tidak mencakup file baru. Lisensi vendor dan keluaran analyze memiliki whitespace bawaan yang baru terlihat saat di-stage.
- Dampak: tiga pemeriksaan commit tertahan, dua pada lisensi dan satu pada log. Tidak ada assertion tes atau pesan diagnostik yang diubah.
- Perbaikan: normalisasi whitespace log dengan assertion seluruh kata tetap sama dan periksa seluruh batch staged sekaligus. Aturan pemeriksaan file vendor/log baru dicatat permanen di AGENTS.md.

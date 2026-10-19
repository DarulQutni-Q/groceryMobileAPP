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

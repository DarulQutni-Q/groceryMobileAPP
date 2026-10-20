# Bukti seller fase A4

Seluruh pemeriksaan fungsional A2-A4 dijalankan ulang pada emulator Android pixel, emulator-5554, dengan backend FastAPI/PostgreSQL lokal. Customer, pembayaran dan push tidak diubah.

## Hasil dan cara mengulang

- Backend: 58 tes HTTP lulus tanpa skip, termasuk PostgreSQL nyata dan transaksi serentak. Ruff dan import lulus; Compose valid, migrasi tetap 0003_pesanan tanpa operasi tertunda.
- Shared: 16 tes lulus. Seller: 32 tes widget/unit lulus, termasuk statistik Beranda, layar 320x568 dan keyboard. Analyzer keduanya No issues found. Total 106 tes, di luar tiga journey perangkat.
- Tiga perjalanan perangkat mencakup auth/toko/produk A2, seluruh perubahan status pesanan A3, dan laporan/offline A4. Bukti eksekusi ada pada [device.log](device.log).
- [backend-smoke.txt](backend-smoke.txt) merekam curl toko kosong, tiga pesanan selesai Rp 135.000, sembilan barang, ranking qty 6/3 dan isolasi seller.
- [28-normal-laporan.png](screens/28-normal-laporan.png) berasal dari APK normal melalui capture native Android. Header, pills dan lima tab tampil lengkap. Ini menutup anomali paint pada beberapa capture integration runner.
- APK akhir berhasil cold start dan memulihkan sesi. Lihat [cold-start.txt](cold-start.txt) dan [29-normal-cold-start](screens/29-normal-cold-start.png). Pada 21 Oktober, tiga pesanan historis tetap ada dan penjualan hari ini nol, sesuai agregat PostgreSQL pada bukti tersebut.
- Offline/retry juga diverifikasi di APK normal dengan kelima tab utuh: [30-normal-beranda-offline](screens/30-normal-beranda-offline.png), [31-normal-online-kembali](screens/31-normal-online-kembali.png), serta [native-network.txt](native-network.txt).
- [git-log.txt](git-log.txt) mencatat lima commit fitur sebelum commit bukti pengujian. Detail endpoint dan contoh curl ada di [A4_API.md](../../A4_API.md).

Perintah yang dipakai dari root, dengan backend dev lokal sudah sehat:

```bash
python3 scripts/smoke_laporan.py --base-url http://127.0.0.1:8000
python3 scripts/verify_seller_a4.py \
  --adb /opt/android-sdk/platform-tools/adb \
  --flutter /home/darulqutni/flutter/bin/flutter
```

Controller menjalankan flutter drive untuk tiga journey, mematikan Wi-Fi dan data emulator melalui ADB, lalu memulihkannya. Lokasi sinyal Directory.systemTemp pada runtime yang diuji adalah code_cache. Koneksi awal dipulihkan dalam finally. Controller dibatasi untuk emulator; tidak memakai mock connectivity pada perjalanan perangkat.

## Checklist layar

| Layar/varian | Bukti screenshot |
| --- | --- |
| Splash, onboarding, login | auth-01-splash, auth-02-onboarding, auth-03-login |
| Daftar tiga langkah dan sukses | auth-04-daftar-akun sampai auth-07-daftar-sukses |
| Beranda tutup dan buka | 01-beranda-tutup, 02-beranda-buka |
| Produk kosong, berisi, toggle, pencarian nihil | 03-produk-kosong, 06-produk, 07-produk-habis, 08-produk-cari-kosong |
| Form produk kosong, validasi gagal dan terisi/foto | 04-tambah-produk, 04-tambah-produk-validasi, 05-tambah-produk-foto |
| Tiga tab pesanan berisi | 01-pesanan-baru, 02-pesanan-diproses, 03-pesanan-selesai |
| Tiga tab pesanan kosong dan aksi refresh | 21-pesanan-baru-kosong, 21-pesanan-diproses-kosong, 21-pesanan-selesai-kosong |
| Detail Baru, Dikemas, Diantar, Selesai | 04-detail-baru, 07-detail-dikemas, 08-detail-diantar, 09-detail-selesai |
| Terima, Urungkan, tolak dan alasan lain | 05-modal-tolak, 06-konfirmasi-terima, 10-modal-lainnya |
| Laporan kosong dan CTA Pesanan | [20-laporan-kosong](screens/20-laporan-kosong.png) |
| Laporan tujuh hari dan tooltip | [22-laporan-7-hari](screens/22-laporan-7-hari.png), [23-laporan-tooltip](screens/23-laporan-tooltip.png) |
| Lima ranking, Lihat semua dan rentang 30 hari | [24-produk-terlaris](screens/24-produk-terlaris.png), [25-laporan-30-hari](screens/25-laporan-30-hari.png) |
| Beranda offline dan koneksi pulih | [26-beranda-offline](screens/26-beranda-offline.png), [27-beranda-online-kembali](screens/27-beranda-online-kembali.png) |
| Menu Toko, Info, Jam Buka | 09-toko, 10-info-toko, 11-jam-buka |
| Pengiriman, rekening, logout/login dan sesi | 12-pengiriman, 13-rekening, 14-sesi-pulih, 12-pesanan-sesi-pulih |

Semua PNG berada di folder [screens](screens/). Journey memeriksa nilai API serta UI, bukan hanya membuka halaman. Dataset laporan perangkat mempunyai tiga pesanan selesai, Rp 275.000 dan 11 barang; ranking mempunyai enam produk, sehingga Lihat semua dapat diuji. Setelah offline/online, statistik Beranda juga harus menunjukkan Rp 275.000, tiga pesanan dan 11 barang.

## Batas verifikasi

- Tidak ada exception Flutter atau overflow pada gate yang lulus. Emulator tetap mengeluarkan diagnostik jank/frame dan IME; pengujian ini tidak membuktikan performa produksi.
- Source laporan berdata, nama kanonis 09-laporan.png/04-beranda.png, font dan file Figma tidak tersedia. Gambar pengguna Pasted image (10) dan (6) menjadi acuan empty/offline. Kesamaan piksel belum tercapai: font, ikon, kurva dan spacing masih berbeda. Tidak ada klaim pixel-identik.
- Sebagian capture integration runner kehilangan layer header/ikon yang statis. Capture APK normal 28 menunjukkan elemen tersebut utuh. Simpan keduanya sebagai bukti asal, jangan menganggap capture yang kehilangan layer sebagai baseline visual final.
- iOS, perangkat fisik, OAuth Google akun nyata, signing rilis dan panggilan pembeli nyata belum diuji. Batas native kamera/lost photo A2 tetap berlaku. Video opsional belum dibuat.
- Journey A1 lama auth_test.dart masih memeriksa placeholder Beranda lama dan tidak dijalankan sebagai gate A4. Journey A2, A3 dan A4 memakai perilaku seller saat ini. Assertion perilaku lama dipertahankan; interaksi logout ditambah konfirmasi dan tombol Back disesuaikan dengan locale Kembali. Assertion placeholder Laporan diganti sesuai tab Laporan yang kini fungsional.

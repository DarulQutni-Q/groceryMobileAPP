# Bukti Fase A2

Pengujian 20 Oktober 2026 memakai backend Docker/PostgreSQL lokal dan emulator Android. Screenshot diambil dari UI Flutter setelah menunggu route, request dan gambar selesai. Viewport emulator 1080x2340 dengan density 420; ukuran logis sekitar 411x891. Tes widget juga memeriksa 320x568 dengan keyboard terbuka.

| File | Isi |
| --- | --- |
| [01-beranda-tutup.png](01-beranda-tutup.png) | Toko baru berstatus tutup, statistik transaksi nol |
| [02-beranda-buka.png](02-beranda-buka.png) | Toggle status tersimpan di backend |
| [03-produk-kosong.png](03-produk-kosong.png) | Katalog awal kosong |
| [04-tambah-produk.png](04-tambah-produk.png) | Form produk sebelum diisi |
| [05-tambah-produk-foto.png](05-tambah-produk-foto.png) | Foto fixture, nama, harga, stok dan kategori diisi |
| [06-produk.png](06-produk.png) | Produk dan foto hasil upload dari backend |
| [07-produk-habis.png](07-produk-habis.png) | Ketersediaan ditoggle, terpisah dari jumlah stok |
| [08-produk-cari-kosong.png](08-produk-cari-kosong.png) | Pencarian tanpa hasil |
| [09-toko.png](09-toko.png) | Menu Toko |
| [10-info-toko.png](10-info-toko.png) | Profil yang diedit, form telah digulir ke bawah |
| [11-jam-buka.png](11-jam-buka.png) | Senin aktif 07.00-23.00, enam hari tutup |
| [12-pengiriman.png](12-pengiriman.png) | Pilihan metode kirim dan radius |
| [13-rekening.png](13-rekening.png) | Rekening contoh yang disimpan |
| [14-sesi-pulih.png](14-sesi-pulih.png) | Beranda setelah logout/login dan rekreasi app |
| [15-cold-start.png](15-cold-start.png) | APK normal dibuka ulang tanpa login, data tetap ada |
| [16-galeri-native.png](16-galeri-native.png) | Foto dipilih melalui galeri sistem Android pada APK normal |
| [verification.txt](verification.txt) | Hasil quality gate backend/shared/seller dan perangkat |
| [cold-start.txt](cold-start.txt) | Langkah dan hasil cold start proses Android |
| [backend-smoke.txt](backend-smoke.txt) | Hasil acceptance curl API toko/produk/foto, termasuk ownership dan validasi |
| [storage-persistence.txt](storage-persistence.txt) | Hash foto tetap sama setelah container backend dibuat ulang |

Journey integrasi mengganti pemilih foto dengan XFile fixture dari aset referensi login. Pemrosesan, upload multipart, penyimpanan, pembacaan foto dan endpoint lain memakai backend nyata. Pemeriksaan terpisah pada APK normal berhasil memilih gambar yang sama melalui galeri sistem Android dan menampilkan preview pada form. Kamera native dan pemulihan lost data setelah Android mematikan proses belum diuji; HP fisik juga belum diuji.

Warna dan susunan mengikuti screenshot sumber, tetapi belum pixel-identik: font sumber tidak tersedia, dekorasi latar serta beberapa ikon/spacing masih berbeda. A2 menambahkan field kategori produk dan mempertahankan empat statistik saat tutup sesuai keputusan pada `A2_PLAN.md`. Logo toko belum memiliki endpoint upload dalam kontrak fase ini.

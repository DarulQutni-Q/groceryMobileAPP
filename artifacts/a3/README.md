# Bukti Fase A3

Pengujian 20 Oktober 2026 memakai backend Docker/PostgreSQL lokal dan emulator Android pixel. Screenshot 01-12 berasal dari perjalanan integrasi dengan API nyata. Ukuran perangkat 1080x2340, density 420; screenshot Flutter tidak memuat status bar sistem. Tes widget juga memeriksa 320x568 dengan keyboard terbuka.

| File | Isi |
| --- | --- |
| [01-pesanan-baru.png](01-pesanan-baru.png) | Tiga pesanan baru, snapshot item, slot, total dan badge |
| [02-pesanan-diproses.png](02-pesanan-diproses.png) | Diproses dengan aksi Tandai siap diantar dan jumlah tab |
| [03-pesanan-selesai.png](03-pesanan-selesai.png) | Satu selesai dan dua ditolak, badge tab otomatis berubah |
| [04-detail-baru.png](04-detail-baru.png) | Detail, timeline awal, pembeli null dan alamat |
| [05-modal-tolak.png](05-modal-tolak.png) | Radio Stok Habis dipilih, tombol konfirmasi aktif |
| [06-konfirmasi-terima.png](06-konfirmasi-terima.png) | Sheet hijau dengan kode, countdown dan Urungkan |
| [07-detail-dikemas.png](07-detail-dikemas.png) | Tahap Dikemas dan aksi Mulai antar |
| [08-detail-diantar.png](08-detail-diantar.png) | Tahap Diantar dan aksi Tandai tiba |
| [09-detail-selesai.png](09-detail-selesai.png) | Timeline selesai, tanpa aksi lanjutan |
| [10-modal-lainnya.png](10-modal-lainnya.png) | Alasan Lainnya dengan teks terisi |
| [11-pesanan-kosong.png](11-pesanan-kosong.png) | Empty state Baru setelah seluruh pesanan ditangani |
| [12-pesanan-sesi-pulih.png](12-pesanan-sesi-pulih.png) | Riwayat setelah rekreasi app dengan sesi tersimpan |
| [backend-smoke.txt](backend-smoke.txt) | Acceptance curl tiga dummy, filter, timeline, alasan, ownership dan snapshot |
| [prod-guard.txt](prod-guard.txt) | Endpoint dummy 404 dan tidak menambah data saat ENV=prod |
| [runtime-checks.txt](runtime-checks.txt) | Compose, Alembic head/check, import serta hash source container |

Customer pada pesanan pengujian null sesuai fase. Nama/telepon memakai `-` dan tombol telepon nonaktif. Pengujian tidak membuat pembeli fiktif, menjalankan pembayaran, mengurangi stok atau mengirim push.

Review independen memeriksa backend, ownership, deadline dan screenshot. Tiga masalah lifecycle/refresh ditemukan lalu diperbaiki dengan tes regresi: refresh daftar tidak menunda sheet terima, undo yang selesai sesudah detail ditutup tidak mengakses ref yang sudah dibuang, dan refresh detail yang gagal menampilkan error tanpa exception tak tertangani.

Acuan yang tersedia hanya daftar Baru `Pasted image (11).png` dan modal tolak `Pasted image (17).png`. Nama kanonis 05/06 dan gambar detail, tab Diproses/Selesai, empty serta sheet terima tidak tersedia. Warna dan susunan mengikuti acuan, tetapi font, ikon, kurva dan spacing belum pixel-identik. Radio/alasan dan batas aksi mengikuti instruksi A3 yang lebih spesifik daripada gambar.

Build/run iOS, HP fisik, panggilan telepon pembeli nyata, flavor staging/prod dan performa produksi belum diuji. Emulator mengeluarkan diagnostik FrameTracker/IME; perjalanan integrasi lulus tanpa exception Flutter atau overflow.

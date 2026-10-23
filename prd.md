# PRD — Aplikasi Grocery (Seller + Customer)

> **DESIGN FIDELITY WAJIB.** Semua screen harus mengikuti screenshot Figma yang terlampir
> (`docs/screenshots/seller/` dan `docs/screenshots/customer/`).
> Layout, warna, tipografi, bahasa (Indonesia), dan alur antar screen harus sama persis
> dengan desain. Jangan improvisasi tampilan. Kalau ada yang ambigu di screenshot,
> ikuti PRD ini sebagai acuan kedua.

## 1. Ringkasan

Dua aplikasi mobile Flutter untuk ekosistem grocery:

| | **Seller App** | **Customer App** |
|---|---|---|
| Nama | Daclanari Grocery (Seller) | GardenMart |
| Pengguna | Pemilik toko kelontong | Pembeli |
| Bahasa | Indonesia | Indonesia |
| Platform | Android + iOS (Flutter) | Android + iOS (Flutter) |

Keduanya terhubung ke satu backend FastAPI yang sama. Dosen juga butuh **dashboard admin web** untuk analisis.

**Deadline:** 2 minggu. **Tim:** 1 orang (solo, 5 nama di kertas).

---

## 2. Seller App — Daclanari Grocery

### 2.1 Onboarding & Auth

| Screen | Elemen | Catatan |
|---|---|---|
| Splash | Logo "daclanari GROCERY", tagline "Belanja Mudah, Kebutuhan Lengkap" | — |
| Onboarding | Ilustrasi, headline "Terima Pesanan dari Satu Layar", tombol Lanjut | Sekali tampil |
| Login | Nama Pemilik, Nama Toko, Kata Sandi (show/hide), Lupa kata sandi, tombol Login, Login dengan Google, tombol Apple, link Daftar | 3 opsi login |
| Lupa Kata Sandi | Instruksi + nama toko, field Email, tombol Kirim Kode Verifikasi | — |
| OTP | 6 kotak OTP, instruksi "kode dikirim ke 0819xxxx", timer kirim ulang 00:40, tombol Lanjut | — |
| Sandi Baru | Sandi baru + konfirmasi, aturan: min 8 maks 20 karakter, 1 huruf + 1 angka, 1 karakter khusus | Validasi inline |

**Registrasi toko (3 langkah):**
1. **Akun** — Nama Pemilik, Nama Toko, Kata Sandi, tombol Daftar
2. **Info Toko** — Kategori chips: Sembako, Sayur, Daging & Ikan, Buah
3. **Pengiriman** — 3 kartu pilihan:
   - Instant: antar 1 jam setelah bayar, min belanja Rp 25rb
   - Kurir Marketplace: kurir ambil di toko
   - Ambil di Toko: pembeli ambil sendiri
   - Slider "Jarak antar maksimal" 1–10 km (default 5 km)
4. **Sukses** — Checklist hijau, "Toko Kamu Sudah Terdaftar", ringkasan, tombol "+ Tambah Produk"

### 2.2 Navigasi Utama (Bottom Nav, 5 tab)

Beranda | Laporan | Produk | Pesanan | Toko

### 2.3 Beranda

- Header: "Toko Daclanari Grocery" + "Selamat Pagi, [nama]"
- Status pill: **Buka** (hijau) / **Tutup** — toggle untuk buka/tutup toko
- Banner notifikasi: "3 Pesan baru menunggu" + tombol Lihat
- 4 kartu statistik:
  - Penjualan hari ini: Rp 500.000 (+12% dari kemarin)
  - Pesanan: 10 (+3 dari kemarin)
  - Produk Terjual: 20 (-7 dari kemarin)
  - Stok Menipis: 3 (Perlu diisi)
- "Perlu Tindakan" — list produk stok kritis:
  - Badge kuning "Sisa 4" → segera isi
  - Badge merah "Habis" → stok kosong
- **Varian tutup:** banner "Toko sedang tutup, pembeli belum bisa memesan" + tombol "Buka Toko"
- **Varian offline:** banner merah "Tidak ada koneksi internet", tombol "Coba lagi"

### 2.4 Pesanan

**Tab:** Baru | Diproses (badge 2) | Selesai (badge 2)

**Kartu pesanan:** ID (DG-12345), jam, nama pembeli, item list, slot pickup ("Hari ini 15.00-17.00"), total, badge status:
- Kuning "Baru", Amber "Diproses", Hijau "Selesai", Merah "Ditolak"

**Aksi:** "Tandai siap diantar" (diproses), "Lihat detail pesanan" (selesai)

**Empty state:** "Belum ada pesanan baru" + ilustrasi

**Detail pesanan (DG-12345):**
- Timeline 4 tahap: Diterima → Dikemas → Diantar → Tiba
- Kartu pembeli: nama + nomor tersensor + tombol telepon
- Alamat + metode pengiriman
- Daftar barang + harga
- Total termasuk ongkir
- Tombol hijau "Terima Pesanan" + merah "Tolak Pesanan"

**Tolak pesanan** → modal "Kenapa pesanan ditolak?":
- Stok Habis / Toko akan ditutup / Alamat di luar jangkauan / Lainnya
- Tombol Batal / Tolak Pesanan (merah)

**Konfirmasi terima** → bottom sheet hijau "Pesanan DG-67890 diterima" + tombol "Urungkan"

### 2.5 Produk

- Search field + tombol "+ Tambah Produk"
- Chips kategori: Semua / Beras / Minyak / ...
- Row produk: thumbnail, nama, ukuran, harga, toggle hijau "Tersedia"
- Badge stok menipis
- **Empty state (search):** "'Biore Guard' belum ada di tokomu..." + tombol tambah
- **Empty state (kosong):** "Tokomu belum punya produk..." + tombol tambah

**Tambah Produk:**
- "Foto Produk Wajib" + ikon kamera
- Nama Produk, Harga (stepper - 0 +), Stok
- Satuan: segmented Kg / pcs / Liter
- Tombol "Simpan produk" (loading: "Menyimpan produk...")

### 2.6 Laporan

- Pills rentang: 7 Hari (aktif) / 30 Hari
- "Total Penjualan 7 hari: Rp 5.550.000" + "+10% dari minggu lalu"
- Bar chart "Penjualan per hari" (Sen–Min)
- "Produk terlaris"
- **Empty state:** "Belum ada data penjualan..." + tombol "Lihat Pesanan"

### 2.7 Toko (Menu)

- Kartu profil: logo, nama, lokasi, rating 4.5
- "Status toko: Buka sampai jam 23.00" + badge "Tersedia"
- Menu: Info Toko | Jam buka | Pengiriman | Rekening Pencairan (BRI ...) | Lihat Panduan Awal | **Keluar** (merah)

**Jam Buka:** rows Senin–Sabtu "07.00–23.00" toggle ON, Minggu "Tutup" toggle OFF, tombol "Simpan Jam Buka"

**Info Toko:** foto/logo + "Ubah Foto", Nama Toko, Kategori chips, Alamat (textarea), Nomor Toko, Deskripsi (opsional), tombol simpan

> **Flag:** tombol simpan di Info Toko tertulis "Simpan produk" — kemungkinan salah label di Figma, harusnya "Simpan".

---

## 3. Customer App — GardenMart

### 3.1 Onboarding & Auth

| Screen | Elemen |
|---|---|
| Awal (splash) | Ilustrasi, logo GardenMart, headline "Belanja Segar & Lengkap Tanpa Ribet", tombol hitam "Get Started" |
| Masuk Akun | Header + tombol "Masuk Akun", kartu: Nomor Handphone, Kata Sandi, Ingat Saya (checked), Lupa Kata Sandi, tombol "Masuk Sekarang", opsi Google & Apple ID, link "Daftar Akun Baru" |
| Daftar Akun | Field email, Kata sandi + Verifikasi kata sandi (eye toggle), tombol Daftar, opsi Google/Apple |
| Lupa Password | Ilustrasi gembok, field email, tombol "Send Email", teks bantuan + email kontak |
| Email Terkirim | "Email Reset Sent!", tombol "Open My Email" |

### 3.2 Navigasi Utama (Bottom Nav, 5 tab)

Beranda | Promo | **Scan QR** (tengah, menonjol) | Pesanan | Akun

### 3.3 Beranda

- Search bar: "Cari promo sembako, susu, snack..." + ikon scan
- Banner promo: "INDOMARET POINKU • PROMO SPESIAL", greeting "Selamat pagi, [nama]", "Ada 4 voucher belanja diskon 50%", tombol "Klaim Semua Voucher"
- **Kartu Poinku Member:** POINKU AKTIF, 14.850 Poin, +250 poin baru, STEMPEL BELANJA 8/10, GOLD TIER, barcode
- 8 ikon kategori: Promo JSM, Tebus Murah, Minyak & Beras, i-Kupon (4), Fresh Mart, Tagihan PLN, Beli 1 Gratis 1, Lacak Kurir
- **Flash sale:** "Kilat Murah Hari Ini", countdown "BERAKHIR: 02:14:35", tombol "Lihat Semua"
- Kartu produk: nama, harga coret, diskon %, "Sisa N pcs"
  - Contoh: Ultra Milk UHT 1000ml Cokelat Rp 17.500 (Rp 21.900) -20%

### 3.4 Keranjang

- Header hijau, info toko: "Dikirim dari Toko Diponegoro", "Estimasi Tiba 15-20 Mnt"
- "Pilih Semua (3 Produk)" + "Hapus"
- Row item: checkbox, gambar, nama, varian, sisa stok, harga, stepper jumlah
- Voucher: "Gunakan / Masukkan Voucher" ("Ada 2 voucher aktif", "Hemat s/d Rp 25rb")
- Total + "Rincian Biaya", tombol "Checkout (N Barang)"
- Banner: "Total kamu hemat Rp 41.600 di pesanan ini!"

### 3.5 Konfirmasi Pesanan

- Alamat Pengiriman (nama, telepon, alamat, catatan)
- Pengantaran: "Kilat Toko (15-20 Menit)", "Rp 0 (Rp 10.000)", "Promo Gratis Ongkir"
- Ringkasan Belanja (N Barang) + "Lihat Semua", estimasi bobot
- Voucher ("Hemat s/d Rp 25rb")
- Metode Pembayaran: GoPay (saldo), "Utama • Saldo Cukup", opsi: GoPay, ShopeePay, Virtual Account BCA, COD
- Rincian: Subtotal, Diskon Voucher, Ongkir (coret → Rp 0), Biaya Layanan Rp 1.000, **Total Tagihan**
- Tombol "Bayar Sekarang"

### 3.6 Pesanan Saya

**Tab:** Dalam Proses (1) | Selesai | Dibatalkan

**Aktif:** nama cabang, "Tiba dalam ~8 Menit", timeline Dikonfirmasi → Dikemas → Dlm Perjalanan → Tiba, kurir (nama, kendaraan, plat), tombol "Chat Driver" + telepon, daftar barang, total

**Riwayat:** cabang, badge Selesai/Dibatalkan, jumlah barang + total, tombol "Beli lagi" + "Lihat struk"

### 3.7 Struk Digital

Header: GARDENMART SUPERMARKET, cabang, telepon. No. Transaksi, tanggal, kasir, kurir. Line items. Total Belanja, Diskon Promo, Diskon Voucher, Ongkir GRATIS, Biaya Layanan, **TOTAL BAYAR**. Metode pembayaran + ID. Poin didapat + stempel. Barcode + QR code. Tombol "Download struk".

### 3.8 Poinku (Loyalty)

- "Total Saldo Aset 14.850 Poin" + tombol History
- "All Rewards": list reward (contoh: kopi gratis 8000 poin), tombol "Tukar" + ikon gembok
- **History:** saldo, bulan, "+50 Poin didapat", rows "+25" per aktivitas

### 3.9 Promo

Header hijau. Tab: Semua Promo | Diskon Belanja | Gratis... Bagian "Promo Mingguan". List voucher: "30% Diskon Produk Segar", "FREE Ongkir Instan s/d Rp 15.000", "+15k Cashback 15.000 Poin".

### 3.10 Scan QR

Viewfinder dengan corner brackets oranye + garis scan. Tombol: galeri (kiri), scan besar (tengah), rotate (kanan). Ikon flashlight.

### 3.11 Notifikasi

Header hijau. Tab: Activities (aktif) | Inbox | Application Status. Chips filter: All, App (aktif), Website. Entries: tanggal + "Payment Successful" + detail + badge "App".

### 3.12 Metode Pembayaran

- DOMPET DIGITAL: GoPay (saldo Rp 445.200, Terhubung, tombol Top Up), ShopeePay (Belum Terhubung, tombol Hubungkan)
- KARTU DEBIT & KREDIT: BCA Mastercard Debit, Mandiri Visa Debit
- PIN Transaksi & Biometrik: toggle ON
- Tombol "Simpan"

### 3.13 Akun Saya

- Profil: nama, telepon, Edit
- Stat cards: POIN SAYA 14.850, stempel 8/10, VOUCHER SAYA 4 Kupon
- Menu: Pesanan Saya (quick icons), Riwayat Belanja, Alamat Pengiriman, Metode Pembayaran, Keamanan Akun & PIN
- Pengaturan: Ubah Profil & Identitas, Verifikasi Identitas & KTP, Ganti kata sandi, PIN & Biometrik, Bahasa Aplikasi, Penyimpanan & Cache (+ Bersihkan)

**Ubah Profil:** avatar, foto, Full name, No HP, Tanggal Lahir (Terverifikasi), email (Terverifikasi), Jenis Kelamin (Perempuan/Laki-laki), tombol Simpan

**Alamat Pengiriman:** search, kartu utama (badge Utama + Rumah, alamat lengkap, catatan, tombol Ubah), ALAMAT LAINNYA (radio selector), GPS pinpoint, tombol "+ Tambah Alamat Baru"

---

## 4. Backend (FastAPI) — Kebutuhan

### 4.1 Domain

- Auth: register/login (email+password, Google, Apple), OTP via WhatsApp/SMS, reset password
- Toko: CRUD profil, jam buka, kategori, metode pengiriman, radius antar
- Produk: CRUD + foto, stok, harga, satuan, toggle tersedia
- Pesanan: create dari customer → notif ke seller → accept/reject → status timeline → selesai/batal
- Pembayaran: integrasi **Xendit** (VA, e-wallet, QRIS)
- Loyalty: poin, stempel, tier, voucher, promo
- Laporan: agregat penjualan harian, produk terlaris
- Push notification: **Firebase FCM** untuk order updates
- Dashboard admin web untuk dosen (analisis)

### 4.2 MVP Scope (2 minggu, solo)

**Wajib jalan:**
1. Auth dua app (email + Google; Apple kalau sempat)
2. Seller: tambah produk, lihat pesanan, terima/tolak, toggle buka/tutup
3. Customer: browse, keranjang, checkout, bayar via Xendit (1 metode cukup: QRIS atau VA)
4. Order flow end-to-end: customer order → seller terima → status update → selesai
5. Push notif order masuk ke seller
6. Dashboard admin: lihat transaksi

**Boleh disederhanakan:**
- Loyalty poin/stempel: tampilkan statis atau skip hitung real
- Multi-metode pengiriman: 1 metode (instant) saja
- Laporan: total + list, chart sederhana
- Voucher: 1 voucher hardcoded atau skip

**Skip dulu:**
- Scan QR, chat driver, verifikasi KTP, multi-bahasa

---

## 5. Screenshot Reference

Setiap fitur di bawah merujuk ke screenshot Figma di `docs/screenshots/`:

**Seller (`docs/screenshots/seller/`):**
| File | Screen |
|---|---|
| `01-overview.png` | Full canvas overview |
| `02-onboarding-login.png` | Onboarding, Login, Lupa password, OTP, Sandi baru |
| `03-register.png` | Register 3 langkah + sukses |
| `04-beranda.png` | Beranda + statistik + offline state |
| `05-pesanan.png` | List pesanan (semua tab + empty state) |
| `06-order-detail.png` | Detail DG-12345 + modal tolak + toast terima |
| `07-produk.png` | List produk + empty states |
| `08-tambah-produk.png` | Form tambah produk + saving state |
| `09-laporan.png` | Laporan + empty state |
| `10-toko.png` | Menu toko, Jam buka, Info toko |

**Customer (`docs/screenshots/customer/`):**
| File | Screen |
|---|---|
| `01-main-cluster.png` | Beranda, Keranjang, Konfirmasi, Pesanan, Struk, Akun, Poinku |
| `02-auth.png` | Login / Sign Up variants |
| `03-onboarding.png` | Splash Awal + Masuk Akun Pembeli |

> Tidak ada screen Promo khusus di Figma — promo tampil di Beranda
> (banner + tombol Klaim + tab Promo di bottom nav).

---

## 6. Kriteria Penilaian (Asumsi)

Dosen kemungkinan menilai: aplikasi jalan end-to-end, fitur sesuai Figma (core), kode rapi, demo lancar, ada backend + database real, payment integrasi real (Xendit sandbox).

---

## 7. Risiko

| Risiko | Mitigasi |
|---|---|
| Scope kebesaran untuk 2 minggu solo | MVP ruthless (bagian 4.2), potong loyalty/QR/chat |
| Xendit butuh verifikasi akun | Pakai sandbox/test key dulu |
| Apple login butuh Apple Developer ($99) | Siapkan UI-nya, logic menyusul; jelaskan ke dosen |
| Firebase setup ribet | FCM saja dulu, tanpa topic yang kompleks |
| Figma ada typo ("Simpan produk" di Info Toko, "Forget Password") | Ikuti maksudnya, bukan teksnya |

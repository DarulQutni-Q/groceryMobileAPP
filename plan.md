# Plan — Eksekusi 2 Minggu (Solo)

> **Acuan desain:** screenshot Figma di `docs/screenshots/seller/` dan
> `docs/screenshots/customer/` (lihat `prd.md` §5 untuk daftar file).
> Setiap screen yang dibangun harus dicocokkan visual dengan screenshot
> sebelum dianggap selesai.

## Prinsip

- **Ruthless MVP.** Yang dinilai: app jalan end-to-end, sesuai Figma (core), backend real, payment real.
- **Satu orang = satu fokus.** Jangan kerjakan dua app paralel. Selesaikan vertikal per fitur.
- **Backend dulu, tipis-tipis.** API jalan → baru UI yang pakai API itu.
- **Potong tanpa ampun:** loyalty hitung real, scan QR, chat driver, verifikasi KTP, multi-bahasa.

---

## Timeline

### Minggu 1: Fondasi + Seller App

| Hari | Fokus | Deliverable |
|---|---|---|
| **1** | Setup + Auth backend | Repo rapi, DB migrate, `POST /auth/*` jalan, JWT bekerja |
| **2** | Toko & Produk backend | CRUD toko, jam buka, produk + upload foto |
| **3** | Pesanan backend | `POST /pesanan` transaksional (stok lock), status flow, terima/tolak |
| **4** | Seller app: auth + home | Splash, login, register 3 langkah, home + statistik + toggle buka/tutup |
| **5** | Seller app: produk + pesanan | List/tambah produk, list pesanan + detail + terima/tolak modal |
| **6** | Seller app: laporan + toko | Laporan ringkas, menu toko, jam buka, info toko |
| **7** | Buffer / bugfix | Seller app selesai 100% MVP, siap demo |

### Minggu 2: Customer App + Integrasi

| Hari | Fokus | Deliverable |
|---|---|---|
| **8** | Customer app: auth + home | Login, register, home + search + kategori + flash sale |
| **9** | Customer app: produk + keranjang | Detail produk, keranjang + stepper + voucher (sederhana) |
| **10** | Checkout + Xendit | Alamat, metode bayar, integrasi Xendit sandbox, webhook |
| **11** | Customer app: pesanan + akun | Tracking timeline, riwayat, struk digital, profil, alamat |
| **12** | FCM push + polish | Notif order ke seller, status ke customer. Rapikan UI dua app |
| **13** | Dashboard admin + testing | Web sederhana (atau endpoint + tabel), test end-to-end penuh |
| **14** | Buffer / demo prep | Video demo, README, siap presentasi |

---

## Urutan Vertikal (Fitur per Fitur)

Kerjakan dalam urutan ini, jangan loncat:

1. **Auth** (backend + seller + customer)
   - Email/password, Google login
   - Lupa password via OTP (bisa mock OTP di dev: tampilkan di log)
2. **Produk** (seller tambah → customer lihat)
   - CRUD + foto (pakai storage lokal/S3 sederhana dulu)
   - Toggle tersedia
3. **Pesanan inti** (customer buat → seller terima/tolak)
   - Transaksi atomik + stok lock
   - Timeline status
4. **Pembayaran** (Xendit)
   - Buat invoice saat checkout
   - Webhook update status → pesanan jadi "baru" untuk seller
5. **Laporan seller** (agregat sederhana)
6. **Profil & pengaturan** (dua app)
7. **Push notification** (FCM)
8. **Dashboard admin** (read-only: transaksi, user, toko)

---

## Definisi Selesai (per Fitur)

- [ ] API endpoint ada + tested via curl/Postman
- [ ] UI sesuai Figma (layout, bukan pixel-perfect)
- [ ] Happy path jalan di HP fisik (bukan cuma emulator)
- [ ] Error state ada (offline, validasi gagal, server error)
- [ ] Tidak ada `print` debug atau TODO di kode yang diserahkan

---

## Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Xendit butuh KYC | Pembayaran tidak bisa live | Pakai **test/sandbox key** — untuk demo cukup |
| Apple login $99 | Fitur kurang satu | UI disiapkan, logic stub + catatan di README |
| Firebase ribet di iOS | Push tidak jalan di iPhone | Fokus Android dulu untuk demo |
| Waktu habis di UI polish | Fitur inti belum jalan | **Fungsi dulu, cantik belakangan.** Hari 12 baru polish. |
| Scope creep ("tambahin ini dong") | Deadline jebol | Setiap tambahan harus ganti sesuatu yang dicoret |

---

## Aturan Main

1. **Commit tiap hari** dengan pesan Bahasa Indonesia yang natural (bukan "feat: ...").
2. **Jangan parallel.** Satu fitur selesai vertikal (backend + UI + test) baru pindah.
3. **Test di HP fisik** minimal 2x seminggu. Emulator menipu.
4. **Hari 7 dan 14 adalah buffer** — jangan rencanakan fitur di hari buffer.
5. Kalau stuck >2 jam di satu masalah, catat dan lanjut ke task lain. Balik lagi besok.

---

## Checklist Demo

- [ ] Seller: daftar toko → tambah produk → terima pesanan → lihat laporan
- [ ] Customer: daftar → cari produk → keranjang → checkout → bayar (Xendit sandbox) → tracking
- [ ] Seller dapat push notif saat ada pesanan baru
- [ ] Dashboard admin menampilkan transaksi
- [ ] Dua HP (atau HP + emulator) demo bareng

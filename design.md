# Design — Arsitektur & Design System

> **DESIGN FIDELITY WAJIB.** Implementasi UI harus pixel-faithful terhadap screenshot
> Figma di `docs/screenshots/seller/` dan `docs/screenshots/customer/`.
> Warna, spacing, radius, tipografi, dan copywriting (Bahasa Indonesia) diambil
> langsung dari screenshot — bukan dari interpretasi bebas. Lihat juga
> `prd.md` §5 untuk pemetaan file screenshot per screen.

## 1. Arsitektur Sistem

```
┌─────────────┐     ┌─────────────┐
│ Seller App  │     │ Customer App│
│  (Flutter)  │     │  (Flutter)  │
└──────┬──────┘     └──────┬──────┘
       │  HTTPS/REST       │  HTTPS/REST
       │  + FCM push       │  + FCM push
       ▼                   ▼
┌─────────────────────────────────┐
│      Backend (FastAPI)          │
│  routers/ services/ models/     │
└──────┬──────────────┬───────────┘
       │              │
       ▼              ▼
  ┌─────────┐   ┌──────────┐
  │PostgreSQL│   │ Firebase │
  │         │   │   FCM    │
  └─────────┘   └──────────┘
       │
       ▼
  ┌─────────┐   ┌──────────┐
  │ Xendit  │   │ Dashboard│
  │(payment)│   │ Admin Web│
  └─────────┘   └──────────┘
```

### 1.1 Monorepo

```
grocery-project/
├── apps/
│   ├── seller/          # Flutter — Daclanari Grocery
│   └── customer/        # Flutter — GardenMart
├── backend/             # FastAPI
│   └── app/
│       ├── main.py
│       ├── core/        # config, security
│       ├── db/          # base, session
│       ├── models/      # SQLAlchemy
│       ├── schemas/     # Pydantic
│       ├── routers/     # endpoints
│       └── services/    # business logic
├── packages/
│   └── shared/          # kode share (opsional)
├── docs/
│   ├── prd.md
│   ├── design.md
│   └── plan.md
└── docker-compose.yml
```

### 1.2 Pola Backend

- **Layered:** Router (HTTP) → Service (logic) → Model (DB)
- **Schemas:** Pydantic untuk request/response, terpisah dari model DB
- **Auth:** JWT (access + refresh). Password di-hash (bcrypt).
- **Transaksi:** `DB::transaction` untuk order create (kurangi stok + buat order atomik)
- **Stok:** `SELECT ... FOR UPDATE` saat checkout untuk cegah oversell

### 1.3 Pola Flutter

- **State management:** Riverpod (atau Bloc — pilih satu, konsisten di dua app)
- **Struktur per app:**
  ```
  lib/
  ├── main.dart
  ├── core/          # theme, constants, utils
  ├── data/          # models, repositories, API client
  ├── features/      # per fitur: auth, home, orders, products, ...
  │   └── <fitur>/
  │       ├── presentation/  # screens, widgets
  │       ├── application/   # providers/notifiers
  │       └── domain/        # entities (opsional)
  └── shared/        # widgets umum
  ```
- **API client:** Dio + interceptor untuk JWT refresh
- **Push:** `firebase_messaging`, handle foreground/background
- **Login sosial:** `google_sign_in`, `sign_in_with_apple`

---

## 2. Design System (dari Figma)

### 2.1 Warna

**Seller (Daclanari):**
| Token | Nilai | Pakai |
|---|---|---|
| Primary | Deep green `#1B5E20`~`#2E7D32` | Tombol, bottom nav aktif, badge |
| Background | Cream/off-white `#FAF7F0`~`#FFF8E1` | Screen |
| Surface | Putih `#FFFFFF` | Card |
| Success | Hijau | Badge Selesai, Tersedia |
| Warning | Kuning/Amber | Badge Baru, Sisa 4 |
| Error | Merah | Badge Habis, Ditolak, tombol hapus |

**Customer (GardenMart):**
| Token | Nilai | Pakai |
|---|---|---|
| Primary | Lime green `#7CB342`~`#9CCC65` | Header, banner |
| Dark | Hitam `#212121` | Tombol utama (Get Started, Bayar) |
| Background | Putih `#FFFFFF` | Screen |
| Accent | Oranye | Corner QR scanner, ilustrasi |

### 2.2 Tipografi

Material Design 3 type scale:
- Display: headline splash/onboarding
- Title: nama screen ("Pesanan", "Laporan")
- Body: konten umum (Bahasa Indonesia)
- Label: tombol (UPPERCASE secukupnya, contoh: "BAYAR SEKARANG")

### 2.3 Komponen

| Komponen | Seller | Customer |
|---|---|---|
| Tombol primer | Hijau deep, rounded penuh | Hitam, rounded penuh |
| Tombol destruktif | Merah | — |
| Badge status | Pill: Baru (kuning), Diproses (amber), Selesai (hijau), Ditolak (merah) | Pill serupa |
| Bottom nav | 5 tab, ikon + label, aktif hijau | 5 tab, tengah Scan QR menonjol |
| Card | Rounded 12–16dp, elevasi ringan | Rounded 12–16dp |
| Text field | Outlined, label Indonesia, eye toggle untuk password | Sama |
| Chips | Kategori (Sembako, Sayur, ...) | Filter promo |
| Toggle | Switch Material | Switch Material |
| Stepper | `- 0 +` untuk harga/stok/jumlah | Sama di keranjang |
| OTP | 6 kotak | — |
| Slider | Radius antar 1–10 km | — |
| Timeline | 4 tahap order (Diterima-Dikemas-Diantar-Tiba) | 4 tahap tracking |
| Modal | Alasan tolak pesanan | — |
| Bottom sheet | Konfirmasi terima + Urungkan | — |

### 2.4 Aturan Visual

- Bahasa: **Indonesia** di semua UI user-facing
- Mata uang: **Rp** dengan pemisah ribuan titik (Rp 96.600)
- Nomor telepon: format +62, sensor tengah untuk privasi (0811 **** 6942)
- Empty state: ilustrasi + teks + tombol aksi (jangan layar kosong)
- Loading: skeleton atau tombol loading ("Menyimpan produk...")
- Offline: banner merah + tombol "Coba lagi"

---

## 3. Model Data (Inti)

```
User (id, nama, email, phone, password_hash, role: seller|customer|admin,
      auth_provider: email|google|apple, fcm_token)

Toko (id, owner_id, nama, logo_url, alamat, telepon, deskripsi,
      kategori[], radius_km, status: buka|tutup,
      metode_kirim[], rekening_bank)

JamBuka (toko_id, hari, jam_buka, jam_tutup, is_tutup)

Produk (id, toko_id, nama, foto_url, harga, stok, satuan: kg|pcs|liter,
         kategori, is_tersedia)

Pesanan (id, kode: DG-xxxxx, customer_id, toko_id,
          status: baru|diproses|dikemas|diantar|selesai|dibatalkan|ditolak,
          alamat_kirim, catatan, metode_kirim, slot_waktu,
          subtotal, diskon, ongkir, biaya_layanan, total,
          tolak_alasan)

PesananItem (pesanan_id, produk_id, nama_snapshot, harga_snapshot, qty)

Pembayaran (pesanan_id, xendit_id, metode, status, amount)

Voucher (id, kode, tipe: persen|nominal|ongkir, nilai, min_belanja, kuota)

PoinTransaksi (user_id, jumlah, alasan, pesanan_id)  # MVP: opsional
```

**Catatan stok:** `harga_snapshot` dan `nama_snapshot` di PesananItem — harga/nama produk bisa berubah, tapi struk order tidak boleh berubah.

---

## 4. API Endpoints (Inti)

```
POST /auth/register          # email + password
POST /auth/login
POST /auth/google            # tukar ID token Google → JWT
POST /auth/apple             # tukar ID token Apple → JWT
POST /auth/forgot-password   # kirim OTP
POST /auth/verify-otp
POST /auth/reset-password

GET  /toko/me                # profil toko seller
PUT  /toko/me
GET  /toko/:id/jam-buka
PUT  /toko/:id/jam-buka

GET  /produk?toko_id=&q=&kategori=
POST /produk                 # + upload foto
PUT  /produk/:id
PATCH /produk/:id/toggle     # tersedia / tidak

POST /pesanan                 # customer checkout (transaksional)
GET  /pesanan?role=seller     # list untuk seller
GET  /pesanan?role=customer   # list untuk customer
GET  /pesanan/:id
PATCH /pesanan/:id/terima
PATCH /pesanan/:id/tolak      # + alasan
PATCH /pesanan/:id/status     # update timeline

POST /pembayaran/xendit       # buat invoice
POST /webhook/xendit          # callback status bayar

GET  /laporan/ringkasan?range=7h|30h
GET  /laporan/produk-terlaris

GET  /voucher                 # list aktif
POST /voucher/klaim
```

---

## 5. Integrasi Pihak Ketiga

| Layanan | Untuk | Catatan |
|---|---|---|
| **Xendit** | Pembayaran | Pakai test key dulu. Mulai dari QRIS atau VA BCA. Webhook untuk update status. |
| **Firebase FCM** | Push notif | Order baru → seller. Status berubah → customer. Simpan `fcm_token` per user. |
| **Google Sign-In** | Login | OAuth client ID per platform (Android/iOS). |
| **Apple Sign-In** | Login | Butuh Apple Developer Program ($99). Siapkan UI + fallback pesan. |

---

## 6. Keputusan Desain Penting

1. **Satu backend, dua app** — bukan dua backend. Lebih gampang maintain solo.
2. **Snapshot harga di order** — harga produk bisa berubah, struk tidak boleh ikut berubah.
3. **Stok dikunci saat checkout** — `FOR UPDATE` untuk cegah dua orang beli stok terakhir barengan.
4. **Status toko (buka/tutup)** — kalau tutup, customer tidak bisa checkout (validasi di backend, bukan cuma UI).
5. **Bahasa Indonesia penuh** — jangan campur Inggris di UI user.
6. **Apple login disiapkan tapi opsional** — kalau tidak sempat verifikasi $99, UI ada + pesan "segera hadir".

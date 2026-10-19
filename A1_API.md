# API akun seller

Semua contoh memakai data contoh. Ganti nilai `<...>` sendiri; jangan commit atau membagikan respons token.

## Daftar seller

`POST /auth/register` mengembalikan 200 beserta access/refresh token. Email duplikat menghasilkan 400. Password harus 8-20 karakter, memuat huruf, angka, dan karakter khusus; input tidak valid menghasilkan 422 dalam Bahasa Indonesia.

```bash
curl -sS http://localhost:8000/auth/register -H 'Content-Type: application/json' -d '{"nama_pemilik":"Pemilik Contoh","nama_toko":"Toko Contoh","email":"pemilik@example.com","password":"Contoh123!","phone":null}'
```

## Login

`POST /auth/login` memakai email/password, maksimal lima percobaan per menit per IP. Gagal kredensial menghasilkan 401; melewati limit menghasilkan 429. Header `X-Forwarded-For` dari klien tidak dipercaya. Reverse proxy deployment harus mengatur trusted proxy secara eksplisit.

```bash
curl -sS http://localhost:8000/auth/login -H 'Content-Type: application/json' -d '{"email":"pemilik@example.com","password":"Contoh123!"}'
```

## Google

`POST /auth/google` memverifikasi ID token, issuer dan audience Google, lalu mencari/membuat seller dari subject Google. Email harus terverifikasi. Akun email yang sudah ada tidak ditautkan otomatis. Konfigurasi belum diisi menghasilkan 503; token invalid menghasilkan 401.

```bash
curl -sS http://localhost:8000/auth/google -H 'Content-Type: application/json' -d '{"id_token":"<id-token-Google>"}'
```

## Refresh

`POST /auth/refresh` menerima refresh token dan mengembalikan pasangan token baru. Token akses berlaku 15 menit dan refresh 7 hari. Keduanya dibedakan lewat claim jenis token. Refresh lama tetap berlaku sampai kedaluwarsa; pencabutan sesi di server belum menjadi bagian A1.

```bash
curl -sS http://localhost:8000/auth/refresh -H 'Content-Type: application/json' -d '{"refresh_token":"<refresh-token>"}'
```

## Profil saat ini

`GET /auth/me` membutuhkan token akses; tanpa token, refresh token, token kedaluwarsa, atau signature salah menghasilkan 401. Respons hanya memuat `id`, `nama`, `email`, `phone`, `role`, `nama_toko`.

```bash
curl -sS http://localhost:8000/auth/me -H 'Authorization: Bearer <access-token>'
```

## Token notifikasi

`PATCH /auth/fcm-token` membutuhkan token akses dan menyimpan token FCM di akun saat ini. Respons 200 berisi `{"message":"Token notifikasi tersimpan"}`.

```bash
curl -sS -X PATCH http://localhost:8000/auth/fcm-token -H 'Content-Type: application/json' -H 'Authorization: Bearer <access-token>' -d '{"fcm_token":"<token-FCM>"}'
```

Push notification tidak diaktifkan pada A1. Seluruh endpoint terdaftar pada `app.main:app`. `GET /health` memeriksa database dan menghasilkan 503 saat koneksi database gagal.

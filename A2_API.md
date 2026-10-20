# API toko dan produk A2

Semua endpoint toko/produk membutuhkan access token seller dari A1. Toko ditentukan dari JWT, bukan `owner_id`/`toko_id` klien. Akses produk seller lain menghasilkan 404. Contoh di bawah memakai placeholder dan data uji.

```bash
API_URL=http://localhost:8000
ACCESS_TOKEN='<access-token-seller>'
```

## Profil toko

Satu toko dibuat otomatis bersama akun seller. Akun A1 mendapat toko melalui migrasi `0002_toko_produk`. Status awal tutup, radius 5 km, kategori/pengiriman kosong, tujuh hari tutup. Registrasi seller A2 kemudian menyimpan pilihan kategori/pengirimannya. Profil kosong dilengkapi lewat menu Toko.

```bash
curl -sS "$API_URL/toko/me" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X PUT "$API_URL/toko/me" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"nama":"Toko Contoh","alamat":"Jalan Contoh 10","telepon":"081234567890","deskripsi":"Toko kelontong","kategori":["Sembako","Sayur"],"radius_km":5,"metode_kirim":["Instant","Ambil di Toko"],"rekening_bank":"BRI 1234567890"}'
curl -sS -X PATCH "$API_URL/toko/me/status" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"status":"buka"}'
```

`PUT /toko/me` juga menerima sebagian field; field yang tidak dikirim tetap tersimpan. Nama toko disinkronkan ke `/auth/me`. Status hanya `buka` atau `tutup`; radius bilangan bulat 1-10. Kategori toko: Sembako, Sayur, Daging dan Ikan, Buah. Pengiriman: Instant, Kurir Marketplace, Ambil di Toko. Rekening/deskripsi boleh null.

## Jam buka

```bash
curl -sS "$API_URL/toko/me/jam-buka" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X PUT "$API_URL/toko/me/jam-buka" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '[{"hari":"senin","jam_buka":"07:00:00","jam_tutup":"23:00:00","is_tutup":false},{"hari":"selasa","is_tutup":true},{"hari":"rabu","is_tutup":true},{"hari":"kamis","is_tutup":true},{"hari":"jumat","is_tutup":true},{"hari":"sabtu","is_tutup":true},{"hari":"minggu","is_tutup":true}]'
```

Wajib tepat tujuh hari unik. Jam memakai waktu lokal tanpa offset. Hari aktif wajib punya jam buka < jam tutup; jam lintas tengah malam tidak diterima. Hari tutup menyimpan jam null. Penggantian jadwal atomik. Jadwal tidak mengubah status toko otomatis.

## Produk

```bash
curl -sS "$API_URL/produk?q=beras&kategori=Beras" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X POST "$API_URL/produk" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"nama":"Beras Contoh","harga":15000,"stok":4,"satuan":"kg","kategori":"Beras"}'
PRODUK_ID='<id-produk-dari-respons>'
curl -sS "$API_URL/produk/$PRODUK_ID" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X PUT "$API_URL/produk/$PRODUK_ID" -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"harga":16000,"stok":10}'
curl -sS -X PATCH "$API_URL/produk/$PRODUK_ID/toggle" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X DELETE "$API_URL/produk/$PRODUK_ID" -H "Authorization: Bearer $ACCESS_TOKEN"
```

Create, update, list, detail dan toggle mengembalikan 200. Delete mengembalikan pesan 200. Nama/kategori tidak boleh kosong; harga integer > 0 dan stok integer >= 0, keduanya maksimal 2.147.483.647. Satuan hanya `kg`, `pcs`, `liter`. Kategori produk berupa teks, misalnya Beras atau Minyak. Validasi gagal 422 dengan pesan Indonesia. Update hanya mengubah field yang dikirim; null tidak diterima pada field produk.

## Upload foto produk

Unggah setelah create dan sebelum menghapus produk. Ganti `<path-foto>` dengan file JPG/PNG/WebP nyata.

```bash
curl -sS -X POST "$API_URL/produk/$PRODUK_ID/foto" -H "Authorization: Bearer $ACCESS_TOKEN" -F 'file=@<path-foto>;type=image/png'
```

Maksimal 5 MB dan 25 megapiksel. MIME, ekstensi, format dan decode gambar diperiksa; JPEG terpotong/file palsu ditolak. Gunakan `image/jpeg` untuk JPG dan `image/webp` untuk WebP. Nama file server UUID, tidak memakai nama/path klien. Respons 200 berupa produk lengkap dengan `foto_url` relatif `/uploads/<uuid>.<ext>`; resolve terhadap origin API agar dapat ditampilkan perangkat. Foto tersebut dapat diunduh tanpa bearer token.

File lama dibersihkan setelah commit penggantian/hapus produk; file baru dibersihkan bila commit gagal. Volume `uploads_data` pada Compose mempertahankan foto saat container dibuat ulang. Kegagalan storage/database menghasilkan pesan 503. Endpoint upload logo toko belum termasuk kontrak A2.

Acceptance curl otomatis, tanpa mencetak password/JWT:

```bash
python3 scripts/smoke_store.py --base-url http://127.0.0.1:8000
```

# B3: checkout dan bayar GardenMart

Checkout alamat, konfirmasi biaya, tujuh metode bayar, COD, invoice Xendit test,
webhook dan polling sudah tersambung. Biaya layanan Rp 1.000 dari server;
ongkir/diskon nol. Tidak ada perubahan task B3 pada apps/seller.

COD telah diuji di emulator dan backend nyata. Pembayaran QRIS sandbox nyata
belum diuji: XENDIT_API_KEY dan XENDIT_WEBHOOK_TOKEN belum disediakan pada
environment lokal. Jangan menyamakan tes transport terkontrol dengan pembayaran
sandbox. Screenshot halaman Xendit belum tersedia karena alasan yang sama.

Lihat [hasil dan screenshot](artifacts/b3/README.md),
[perubahan per file](artifacts/b3/changes.md),
[tabel HTTP](artifacts/b3/http-results.md), dan [keputusan](B3_PLAN.md).

## Endpoint

Semua endpoint customer memerlukan JWT customer. Webhook memakai token callback.

| Method | Path | Hasil |
| --- | --- | --- |
| GET | /alamat | Array alamat sendiri, utama dahulu |
| POST | /alamat | 201 alamat baru; alamat pertama otomatis utama |
| PUT | /alamat/{id} | Ubah isi alamat sendiri |
| DELETE | /alamat/{id} | 204; jika utama dihapus, alamat berikut menjadi utama |
| PATCH | /alamat/{id}/jadikan-utama | Jadikan satu alamat sebagai utama |
| POST | /checkout/preview | Rincian harga DB tanpa membuat pesanan |
| POST | /checkout | 201 berisi pesanan, pembayaran, payment_url |
| GET | /pembayaran/{id}/status | Status milik customer, termasuk perlu_rekonsiliasi |
| POST | /webhook/xendit | Callback invoice; token salah/tidak ada 403 |
| GET | /pesanan | Customer: data/meta miliknya; seller mempertahankan kontrak lama |
| GET | /pesanan/{id} | Detail milik customer/seller terkait |

Alamat pihak lain 403; ID tidak ada 404; tipe/range tidak valid 422 Indonesia.
Checkout produk hilang/tidak tersedia/toko tutup/stok kurang 400. Pengiriman
hanya Instant, Kurir Marketplace, Ambil di Toko. Harga/total kiriman tambahan
ditolak; total_dikonfirmasi opsional mengembalikan409 jika harga berubah.

## Contoh curl

Jalankan terhadap akun lokal sendiri. Isi TOKEN dengan access_token hasil login,
ALAMAT_ID dengan GET /alamat dan PRODUK_1/PRODUK_2 dengan katalog toko yang sama.
Jangan menyimpan token ke repo atau mengirimkannya ke chat.

```bash
API_URL=http://127.0.0.1:8000
curl "$API_URL/alamat" -H "Authorization: Bearer $TOKEN"

curl -X POST "$API_URL/alamat" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"label":"Rumah","nama_penerima":"Pembeli","no_hp":"081234567890","alamat_lengkap":"Jalan Melati 10","patokan":"Pagar hijau"}'

curl -X PUT "$API_URL/alamat/$ALAMAT_ID" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"label":"Kantor","nama_penerima":"Pembeli","no_hp":"081234567890","alamat_lengkap":"Jalan Kantor 20"}'

curl -X PATCH "$API_URL/alamat/$ALAMAT_ID/jadikan-utama" \
  -H "Authorization: Bearer $TOKEN"

curl -X DELETE "$API_URL/alamat/$ALAMAT_ID" -H "Authorization: Bearer $TOKEN"
```

Contoh DELETE dilakukan pada alamat tambahan; pilih alamat yang masih ada untuk
checkout. Gunakan qty1 dari dua produk yang tersedia, bukan harga dari client.

```bash
jq -n --arg alamat "$ALAMAT_ID" --arg p1 "$PRODUK_1" --arg p2 "$PRODUK_2" \
  '{alamat_id:$alamat,metode_kirim:"Instant",metode_bayar:"qris",catatan:"Pagar hijau",items:[{produk_id:$p1,qty:1},{produk_id:$p2,qty:1}]}' \
  > /tmp/checkout-b3.json

curl -X POST "$API_URL/checkout/preview" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' --data-binary @/tmp/checkout-b3.json

CHECKOUT_KEY=$(python3 -c 'import time,secrets; print(str(int(time.time()*1000))+"-"+secrets.token_hex(16))')
curl -X POST "$API_URL/checkout" -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: $CHECKOUT_KEY" -H 'Content-Type: application/json' \
  --data-binary @/tmp/checkout-b3.json

curl "$API_URL/pembayaran/$PEMBAYARAN_ID/status" -H "Authorization: Bearer $TOKEN"
curl "$API_URL/pesanan?page=1&per_page=20" -H "Authorization: Bearer $TOKEN"
curl "$API_URL/pesanan/$PESANAN_ID" -H "Authorization: Bearer $TOKEN"
```

Untuk COD, ubah metode_bayar menjadi cod dan gunakan key baru. Untuk retry
request yang sama, pertahankan key serta payload persis. Jangan membuat key baru
ketika respons invoice timeout dan hasilnya belum diketahui.

Callback uji berikut membutuhkan invoice sandbox yang identitas/nominalnya
cocok. EXTERNAL_ID adalah GM- diikuti CHECKOUT_KEY; XENDIT_ID diambil dari
invoice pada Dashboard test. Token harus sama dengan konfigurasi backend.

```bash
jq -n --arg id "$XENDIT_ID" --arg external "$EXTERNAL_ID" --argjson amount "$TOTAL" \
  '{id:$id,external_id:$external,status:"PAID",amount:$amount,paid_amount:$amount,currency:"IDR"}' \
  > /tmp/callback-b3.json

curl -X POST "$API_URL/webhook/xendit" -H 'Content-Type: application/json' \
  --data-binary @/tmp/callback-b3.json

curl -X POST "$API_URL/webhook/xendit" -H 'Content-Type: application/json' \
  -H "X-CALLBACK-TOKEN: $XENDIT_WEBHOOK_TOKEN" --data-binary @/tmp/callback-b3.json
```

Tanpa token hasil403. Token/identitas/nominal benar menghasilkan200 paid;
ulang callback yang sama tetap paid dan tidak mengurangi stok lagi. Simulasi
curl PAID adalah tes webhook, bukan bukti QRIS dibayar melalui Xendit.

## Menyiapkan sandbox

1. Buat API key dalam mode Test Xendit. Hanya prefix xnd_development yang
   diterima B3; production key ditolak saat startup.
2. Salin verification token Dashboard test ke XENDIT_WEBHOOK_TOKEN. Simpan
   XENDIT_API_KEY dan XENDIT_WEBHOOK_TOKEN di backend/.env yang diabaikan
   Git. Isi juga konfigurasi database/JWT yang diperlukan. Jangan mencetak nilai.
3. Compose memerlukan variabel host. Dari root gunakan
   `docker compose --env-file backend/.env up -d --build backend`.
   File tersebut harus memuat POSTGRES_PASSWORD dan JWT_SECRET yang sesuai
   database lokal, bukan mengganti password database yang sudah ada.
4. Pada konfigurasi callback Invoice Dashboard test, arahkan ke URL HTTPS publik
   yang meneruskan `/webhook/xendit` ke backend. Localhost tidak dapat dijangkau
   Xendit. Jangan menggunakan endpoint webhook produk lain dengan payload berbeda.
5. Buat checkout QRIS, buka payment_url asli di browser, selesaikan simulasi yang
   tersedia pada halaman sandbox dan kembali ke app. Polling membaca hasil
   webhook tiap 3 detik, berhenti maksimal 2 menit per jendela pemeriksaan.
   Tombol Periksa Status menjalankan pemeriksaan berikutnya bila perlu.
6. Paid menghasilkan sukses dan pembersihan item yang dibeli. COD menghasilkan
   sukses pesanan dengan pembayaran tetap pending. Expired/failed mengembalikan
   reservasi satu kali dan menawarkan Coba Lagi.

App memakai browser eksternal melalui url_launcher yang sudah tersedia, sesuai
pilihan yang diizinkan pada permintaan B3. Tidak menambah dependency WebView.
GoPay dapat memerlukan aplikasi GoPay untuk otorisasi; uji pada perangkat yang
mendukung metode tersebut sebelum menyatakan channel itu lolos end-to-end.

Referensi primer: [Invoice SDK](https://github.com/xendit/xendit-python/blob/master/docs/InvoiceApi.md),
[API Invoice](https://archive.developers.xendit.co/api-reference/#list-all-invoices),
[API key](https://help.xendit.co/hc/en-us/articles/16516398053273-What-is-API-Key-and-How-Do-I-Create-Them),
[GoPay](https://docs.xendit.co/docs/gopay).

## Transaksi, retry dan rekonsiliasi

Pesanan/items/pembayaran dan stok memakai satu transaksi DB. Attempt disimpan
lebih dahulu sebagai audit sebelum RPC; itu bukan pesanan setengah jadi.
Harga disalin dari DB, row toko/produk dikunci berurutan dan stok dikurangi
saat checkout. Seller tidak dapat menerima non-COD yang belum paid.

external_id Xendit tidak unik. Setelah timeout, server mencari invoice dengan
external_id yang sama dan tidak mengirim POST invoice kedua secara otomatis.
Hasil kosong/lebih dari satu tetap503 untuk pemeriksaan; jangan memaksa retry
dengan key lain. Tidak ada janji transaksi atomik lintas gateway dan database.
Jika proses berhenti sesudah attempt dicatat tetapi sebelum RPC, dibutuhkan
pemeriksaan operator karena belum ada bukti invoice dibuat atau tidak.

Dana yang masuk setelah pesanan dibatalkan tetap dicatatpaid dengan
perlu_rekonsiliasi=true; order tetap batal dan stok tidak dipotong ulang.
Callback menghasilkan409 agar kasus ini tidak dianggap selesai normal.
Refund otomatis tidak termasuk B3. Attempt orphan yang menerima callback
menyimpan identitas/status untuk pemulihan dengan key sama atau pemeriksaan.
Jangan menghapus attempt yang hasil RPC-nya belum diketahui.

Migrasi berurutan: 0005_alamat, 0006_checkout_attempt, 0007_pembayaran,
0008_attempt_outcome, 0009_payment_reconcile. Upgrade/downgrade SQLite/PostgreSQL
serta kesesuaian metadata telah diuji. Jalankan migrasi melalui Alembic;
jangan memakai AUTO_CREATE_TABLES untuk mengganti migrasi pada deployment.

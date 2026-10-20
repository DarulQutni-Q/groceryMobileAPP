# API pesanan A3

Semua endpoint membutuhkan JWT seller A1. Toko berasal dari pemilik token; membaca atau mengubah pesanan toko lain menghasilkan 404. Response memuat snapshot item, total, status, alasan penolakan, waktu UTC dan data pembeli nullable. Nominal rupiah berupa integer.

| Metode | Endpoint | Perilaku |
| --- | --- | --- |
| GET | `/pesanan?status=baru` | Daftar terbaru dahulu; filter opsional `baru`, `diproses`, `selesai` |
| GET | `/pesanan/{id}` | Detail beserta seluruh item |
| PATCH | `/pesanan/{id}/terima` | Baru menjadi Diproses |
| PATCH | `/pesanan/{id}/tolak` | Baru menjadi Ditolak; body `alasan` wajib |
| PATCH | `/pesanan/{id}/status` | Satu tahap maju atau pembatalan sebelum terminal |
| PATCH | `/pesanan/{id}/urungkan` | Diproses kembali Baru sebelum 10 detik sejak diterima |
| POST | `/pesanan/internal/test` | Membuat satu pesanan pengujian, hanya `ENV=dev` |

## Menyiapkan dev dan data

`ENV` default `prod`, termasuk pada Compose dan contoh environment. Jalankan `ENV=dev docker compose up -d --build backend` dengan environment database/JWT yang sudah diisi. Endpoint dummy pada prod, staging, nilai kosong atau ENV yang tidak diisi menghasilkan 404 dan tidak membuat pesanan. Flavor Flutter tidak mengaktifkan endpoint ini.

Contoh memakai placeholder token dan UUID. Ganti dengan hasil register/login A1 dan produk toko sendiri dari A2. Jangan membagikan respons token.

```bash
API_URL=http://localhost:8000
ACCESS_TOKEN='<access-token-seller>'
PRODUK_ID='<uuid-produk-milik-seller>'
for n in 1 2 3; do
  curl -sS -X POST "$API_URL/pesanan/internal/test" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "{\"items\":[{\"produk_id\":\"$PRODUK_ID\",\"qty\":2}],\"alamat_kirim\":\"Jalan Contoh 3\",\"slot_waktu\":\"Hari ini 15.00-17.00\",\"ongkir\":5000}"
done
curl -sS "$API_URL/pesanan?status=baru" -H "Authorization: Bearer $ACCESS_TOKEN"
```

Simpan tiga ID yang berbeda dari respons sebagai `PESANAN_ID`, `TOLAK_ID`, dan `BARU_ID`. Dengan produk seharga Rp 15.000, contoh di atas menghasilkan subtotal 30.000 dan total 35.000.

Body dummy boleh dihilangkan: server mengambil satu produk toko sendiri dengan qty 1. Katalog kosong menghasilkan 422. Body menerima `items`, `alamat_kirim`, `catatan`, `metode_kirim`, `slot_waktu`, `diskon`, `ongkir`, `biaya_layanan`; tidak menerima toko, customer, status, harga snapshot atau total dari klien. Daftar maksimal 100 produk unik, qty integer 1-10.000. Biaya nonnegatif; diskon tidak boleh melebihi subtotal. Total dihitung server dan dibatasi rentang integer database.

Kode unik `DG-xxxxx` dibuat acak di server; tabrakan dicoba ulang hingga lima kali, kemudian 503 tanpa pesanan/item parsial. Nama dan harga disalin saat pembuatan. Edit/hapus produk tidak mengubah riwayat; setelah produk dihapus, `produk_id` item menjadi null dan snapshot tetap ada. Dummy tidak memotong stok, menjalankan checkout atau pembayaran.

## Detail dan timeline

```bash
PESANAN_ID='<uuid-pesanan-pertama>'
TOLAK_ID='<uuid-pesanan-kedua>'
BARU_ID='<uuid-pesanan-ketiga>'
curl -sS "$API_URL/pesanan/$PESANAN_ID" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X PATCH "$API_URL/pesanan/$PESANAN_ID/terima" -H "Authorization: Bearer $ACCESS_TOKEN"
```

Sesaat setelah terima, pengecualian yang disetujui adalah Urungkan. Server memeriksa deadline dan status di bawah row lock; countdown perangkat hanya tampilan. `accepted_at`, `undo_until`, dan `server_time` memakai UTC. Setelah deadline, atau jika pesanan sudah dikemas, endpoint menghasilkan 400.

```bash
curl -sS -X PATCH "$API_URL/pesanan/$PESANAN_ID/urungkan" -H "Authorization: Bearer $ACCESS_TOKEN"
curl -sS -X PATCH "$API_URL/pesanan/$PESANAN_ID/terima" -H "Authorization: Bearer $ACCESS_TOKEN"
for status in dikemas diantar selesai; do
  curl -sS -X PATCH "$API_URL/pesanan/$PESANAN_ID/status" \
    -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"status\":\"$status\"}"
done
```

Urutan normal: baru, diproses, dikemas, diantar, selesai. `/status` dapat melakukan satu langkah berikutnya; `/terima` adalah pintasan ke Diproses. Status selesai, ditolak dan dibatalkan bersifat terminal. Pembatalan hanya dari status nonterminal. Penolakan hanya dari Baru melalui `/tolak`; `/status` tidak dapat melewati validasi alasan.

## Penolakan dan validasi

```bash
curl -sS -X PATCH "$API_URL/pesanan/$TOLAK_ID/tolak" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{}'
curl -sS -X PATCH "$API_URL/pesanan/$TOLAK_ID/tolak" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"alasan":" "}'
curl -sS -X PATCH "$API_URL/pesanan/$TOLAK_ID/tolak" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"alasan":"Stok Habis"}'
curl -sS -X PATCH "$API_URL/pesanan/$BARU_ID/status" \
  -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json' -d '{"status":"selesai"}'
curl -sS "$API_URL/pesanan?status=selesai" -H "Authorization: Bearer $ACCESS_TOKEN"
```

Dua penolakan awal menghasilkan 422; penolakan valid menghasilkan 200 dengan `tolak_alasan` tersimpan. Alasan di-trim, maksimal 1.000 karakter. Lompatan Baru langsung Selesai menghasilkan 400. Transisi mundur, terminal, dan kondisi konkurensi yang sudah mengubah status juga ditolak.

Tab Baru hanya memuat `baru`. Diproses mencakup `diproses/dikemas/diantar`; Selesai mencakup `selesai/dibatalkan/ditolak`. Tanpa filter, seluruh pesanan toko sendiri dikembalikan, tetap memakai status asli. Parameter filter tidak dikenal menghasilkan 422. Customer null ditampilkan sebagai `-` dan tombol telepon dinonaktifkan.

Acceptance curl otomatis membuat tiga pesanan, memeriksa semua jalur di atas, ownership dan ketahanan snapshot tanpa mencetak kredensial:

```bash
python3 scripts/smoke_pesanan.py --base-url http://127.0.0.1:8000
git log --oneline -5
```

Hasil aktual dan screenshot ada di `artifacts/a3/README.md`.

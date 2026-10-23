# Hasil HTTP backend lokal B3

| Method | Endpoint | Expected | Actual |
| --- | --- | --- | --- |
| GET | /health | 200 | 200 |
| POST | /auth/register | 200 | 200 |
| POST | /auth/register | 200 | 200 |
| POST | /auth/register | 200 | 200 |
| PATCH | /toko/me/status | 200 | 200 |
| POST | /produk | 200 | 200 |
| POST | /produk | 200 | 200 |
| POST | /alamat | 201 | 201 |
| POST | /alamat | 201 | 201 |
| GET | /alamat | 200 | 200 |
| GET | /alamat | 200 | 200 |
| PUT | /alamat/2fdec6b4-cf80-451f-8cbf-d1b550380266 | 200 | 200 |
| PATCH | /alamat/2fdec6b4-cf80-451f-8cbf-d1b550380266/jadikan-utama | 200 | 200 |
| PATCH | /alamat/cb2096c3-d5e9-4978-9a1b-310ce27a6806/jadikan-utama | 200 | 200 |
| PUT | /alamat/cb2096c3-d5e9-4978-9a1b-310ce27a6806 | 403 | 403 |
| DELETE | /alamat/cb2096c3-d5e9-4978-9a1b-310ce27a6806 | 403 | 403 |
| PATCH | /alamat/cb2096c3-d5e9-4978-9a1b-310ce27a6806/jadikan-utama | 403 | 403 |
| DELETE | /alamat/2fdec6b4-cf80-451f-8cbf-d1b550380266 | 204 | 204 |
| POST | /checkout | 403 | 403 |
| POST | /checkout | 400 | 400 |
| GET | /pesanan | 200 | 200 |
| POST | /checkout | 422 | 422 |
| POST | /checkout | 422 | 422 |
| POST | /checkout | 422 | 422 |
| POST | /checkout/preview | 200 | 200 |
| POST | /checkout | 503 | 503 |
| POST | /checkout | 201 | 201 |
| POST | /checkout | 201 | 201 |
| GET | /pembayaran/827ae4d8-a014-4964-82a0-a29661ce6e57/status | 200 | 200 |
| GET | /pembayaran/827ae4d8-a014-4964-82a0-a29661ce6e57/status | 403 | 403 |
| GET | /pesanan/d63356ef-6743-4b9d-a617-f7adddd50330 | 200 | 200 |
| GET | /pesanan/d63356ef-6743-4b9d-a617-f7adddd50330 | 404 | 404 |
| POST | /webhook/xendit | 403 | 403 |
| GET | /alamat | 401 | 401 |
| GET | /pembayaran/827ae4d8-a014-4964-82a0-a29661ce6e57/status | 401 | 401 |
| POST | /checkout | 401 | 401 |

Seluruh 36 request memenuhi status yang diharapkan; tidak ada respons 500.
QRIS 503 adalah hasil yang diharapkan saat kredensial belum tersedia, bukan pembayaran sandbox berhasil.
Callback bertoken benar dan idempotensinya diuji pada HTTP TestClient dengan database nyata dan transport gateway terkontrol.

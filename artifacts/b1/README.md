# Bukti B1 customer

Screenshot 01-04 mengikuti empat acuan customer yang tersedia.
03-register-phone menambahkan field HP sesuai pilihan pengguna.
05-email-sent-preview adalah preview UI, bukan bukti pengiriman email.
06-08 membuktikan register, restore sesi dan login HP ke backend lokal.

| Endpoint | Input | Expected | Actual |
| --- | --- | --- | --- |
| GET /health | valid | 200 | 200 |
| POST /auth/register | role admin | 422 | 422 |
| POST /auth/register | HP invalid | 422 | 422 |
| POST /auth/register | password invalid | 422 | 422 |
| POST /auth/register | customer + HP | 200 | 200 |
| GET /auth/me | valid | 200 | 200 |
| POST /auth/register | duplicate canonical phone | 400 | 400 |
| POST /auth/refresh | customer refresh | 200 | 200 |
| PATCH /auth/fcm-token | valid | 200 | 200 |
| GET /toko/me | customer cannot access seller | 403 | 403 |
| POST /auth/google | role admin | 422 | 422 |
| POST /auth/login/phone | registered HP | 200 | 200 |
| POST /auth/login | customer email explicit role | 200 | 200 |
| POST /auth/login/phone | wrong password | 401 | 401 |
| POST /auth/login | legacy default seller | 401 | 401 |
| POST /auth/login/phone | unknown phone | 401 | 401 |
| POST /auth/login/phone | sixth shared login attempt | 429 | 429 |
| POST /auth/register | malformed JSON | 422 | 422 |
| POST /auth/forgot-password | endpoint absent, UI shows soon | 404 | 404 |

Tidak ada HTTP500 pada 19 kasus ini. Suite backend150, customer11, shared20 dan seller32 lulus.
Lihat B1_API.md untuk perintah, perubahan per file dan batas pengujian.

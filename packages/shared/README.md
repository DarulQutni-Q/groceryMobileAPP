# Grocery shared

Package Flutter untuk model User, client Dio, API auth dan secure storage. Tidak berisi screen khusus seller/customer.

`ApiClient` menambahkan token Bearer, menggabungkan refresh serentak menjadi satu request per sesi, dan mengulang request paling banyak sekali. Request dari akun lama tidak diteruskan memakai akun baru. Refresh yang ditolak menghapus sesi dan memanggil callback logout.

`SecureStorage` menyimpan pasangan token dalam satu nilai JSON, terpisah dari flag onboarding. Kegagalan operasi dikembalikan ke pemanggil; antrean operasi dapat dipakai lagi setelah retry.

```bash
flutter analyze
flutter test
```

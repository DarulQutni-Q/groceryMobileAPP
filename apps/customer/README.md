# GardenMart customer

B1 menyediakan splash, login HP, daftar dengan email dan HP, lupa sandi,
preview email terkirim, serta Home placeholder dengan sesi tersimpan.

Dari folder ini:

```sh
flutter pub get
flutter analyze
flutter test
flutter run --flavor dev -t lib/main_dev.dart
```

Dev memakai API http://10.0.2.2:8000. Staging/prod membaca env contoh masing-masing
atau --dart-define=API_BASE_URL dan wajib HTTPS. Target Dart main_staging.dart /
main_prod.dart sesuai flavor. GOOGLE_CLIENT_ID dapat diisi lewat dart-define;
OAuth/signing native perlu dikonfigurasi sebelum menguji akun Google nyata.

Tes perangkat:

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_test.dart --flavor=dev -d emulator-5554
```

Tes membuat akun customer uji di backend lokal dan menulis screenshot ke
../../artifacts/b1. Email terkirim pada screenshot adalah preview rute, sebab
endpoint reset belum tersedia. Detail kontrak, bukti dan batas ada di ../../B1_API.md.

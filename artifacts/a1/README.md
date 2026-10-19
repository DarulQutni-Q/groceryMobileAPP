# Bukti Fase A1

Diambil dari emulator Android pada 20 Oktober 2026. Data toko pada gambar adalah data uji.

| Layar | Screenshot |
| --- | --- |
| Splash | [01-splash.png](01-splash.png) |
| Onboarding | [02-onboarding.png](02-onboarding.png) |
| Login | [03-login.png](03-login.png) |
| Opsi Google/Apple dan footer login | [03b-login-options.png](03b-login-options.png) |
| Register akun | [04-register-akun.png](04-register-akun.png) |
| Register info toko | [05-register-info-toko.png](05-register-info-toko.png) |
| Register pengiriman | [06-register-pengiriman.png](06-register-pengiriman.png) |
| Register sukses | [07-register-sukses.png](07-register-sukses.png) |
| Beranda placeholder | [08-home.png](08-home.png) |
| Beranda setelah proses dihentikan dan dibuka ulang | [09-cold-start.png](09-cold-start.png) |

[backend-smoke.txt](backend-smoke.txt) memuat hasil acceptance curl ke Docker/PostgreSQL. [cold-start.txt](cold-start.txt) mencatat pemeriksaan persistensi sesi pada APK normal.

Screenshot memperlihatkan implementasi saat ini, bukan bukti pixel-identik. Selisih visual serta Google nyata, iOS, dan pemeriksaan lain yang belum dijalankan dijelaskan di [handoff.md](../../handoff.md).

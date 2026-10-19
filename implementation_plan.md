# Rencana setup Grocery Apps

Status: arsip rencana setup awal. Rencana aktif sekarang ada di `A1_PLAN.md`.

## Sumber dan kondisi awal

- Sumber: `/home/darulqutni/downloads/AI_AGENT_SETUP_PROMPT.md`, dibaca pada 19 Oktober 2026.
- Batasan eksplisit: **"setup struktur direktori dan stack saja"**, **"JANGAN menulis kode fitur"**, dan **"Jangan mengubah apapun di docs/"**.
- Workspace belum berisi kode, PRD, design, screenshot, atau aturan proyek tambahan. Dokumen final akan diberikan pengguna sesudah setup; jangan membuat isi penggantinya.
- Cache SDK yang diperiksa mencatat Flutter 3.47.7, channel stable, Dart 3.13.5. Versi stable terbaru daring belum diverifikasi.
- Docker 29.9.1, Compose 5.6.0, Java 21, Python 3.14.7, dan uv tersedia. Android SDK ada; kelengkapan toolchain belum diuji. CocoaPods tidak tersedia di host Linux ini.
- Workspace bukan repositori Git aktif. Tidak melakukan init, commit, push, atau tag.

## Pohon keputusan

- Root: gunakan workspace `groceryMobileAPP` sebagai root proyek; tidak menambah folder `grocery-project` di dalamnya.
- Mobile: dua project Flutter untuk Android dan iOS, dengan ID `com.daclanari.seller` dan `com.gardenmart.customer`.
  - UI: hanya teks awal yang diminta, memakai widget bawaan Material; tidak membuat design system atau widget fitur.
  - State: Riverpod di kedua app; shared package didaftarkan lewat path relatif.
  - Environment: entry point dev/staging/prod, native flavors/schemes, nama app dan application ID berbeda, `.env` per flavor hanya berisi contoh konfigurasi publik.
  - Shared: struktur API/model/theme/widget disediakan tanpa implementasi fitur. Package menggunakan dependency Flutter SDK bila diperlukan oleh kontrak notifikasi.
  - **Perlu konfirmasi:** rekomendasi memakai `NotificationService` sebagai stub dengan kontrak lifecycle dan struktur native channel `order_updates`, sesuai bagian Deliverable. Registrasi token ke backend, tampilan notifikasi, dan aktivasi Firebase menunggu kredensial dan fase implementasi. Bagian Production Requirements meminta perilaku lebih lengkap daripada Deliverable yang menyebut stub.
- Backend: FastAPI, SQLAlchemy, Pydantic v2, PostgreSQL 16, Alembic, dan dependency yang diminta.
  - Koneksi DB berasal dari environment. `/health` mengeksekusi query DB; kegagalan menghasilkan status tidak sehat.
  - Logging JSON dan request ID dipasang pada entry point FastAPI; Sentry opsional melalui environment.
  - Pembayaran: route invoice dan webhook terdaftar, tetapi operasi pembayaran tetap stub. Webhook tanpa token valid ditolak 403; stub tidak melaporkan pembayaran berhasil.
  - Auth: konfigurasi access token 15 menit/refresh 7 hari, dependency secure storage, struktur rate limiter dan keamanan; tidak membuat alur login atau refresh token.
  - Model: hanya kerangka minimal User/Pembayaran untuk field integrasi yang diwajibkan; tidak membuat model domain lengkap.
- Infrastruktur: Dockerfile, Compose db/backend, healthcheck dan environment contoh tanpa kredensial nyata. Tidak menjalankan provisioning eksternal.
- Dokumen: README root dan per app, catatan keputusan setup serta handoff di root; seluruh isi `docs/` yang mungkin diberikan pengguna tetap tidak disentuh.

## Urutan implementasi setelah konfirmasi

1. Verifikasi SDK/dependency resmi dan hasilkan skeleton Flutter memakai toolchain yang tersedia.
2. Siapkan shared package, dependency kedua app, entry point dan konfigurasi native tiga flavor.
3. Siapkan backend minimal, environment, route health, middleware, model integrasi minimal, dan stub pembayaran/push.
4. Tambahkan Docker Compose serta petunjuk penggunaan dan pekerjaan manual.
5. Jalankan verifikasi, lakukan review independen secara read-only, lalu laporkan hasil dan gap.

## Peta dampak dan keterjangkauan

| Area | Pemanggil/konsumen | Pemeriksaan |
| --- | --- | --- |
| `packages/shared` | Dua app melalui path dependency | Resolusi dependency dan analyzer kedua app/shared |
| Entry point dan environment | Flutter run/build setiap flavor | Analyze, tes boot app, inspeksi native flavor/scheme |
| FastAPI | Uvicorn dan container backend | Import, tes HTTP melalui app ASGI |
| Health DB | `/health` dan healthcheck Compose | Respons sehat saat DB tersedia; gagal sehat saat DB tidak tersedia |
| Pembayaran dan middleware | Router/middleware yang dipasang di `app.main` | HTTP 403 webhook invalid, stub tidak mengembalikan sukses palsu, request ID/CORS |
| Config/container | Docker Compose dan Settings backend | Validasi environment dan `docker compose config` |

Belum ada kode produksi atau konsumen lama yang dapat terdampak. Risiko bersama berada pada dependency shared, pemetaan flavor native, dan konfigurasi backend/container. Tidak mengubah sistem global atau SDK di luar workspace tanpa otorisasi tool yang diperlukan.

## Gerbang verifikasi

- Temukan dan jalankan perintah analyze/test/build dari project yang dihasilkan; hasil kegagalan dilaporkan dan tidak disamarkan.
- `flutter analyze` pada seller, customer, dan shared; uji tampilan awal melalui entry point publik bila toolchain mendukung.
- Pemeriksaan konfigurasi dev/staging/prod Android/iOS, termasuk ID dan pemetaan entry point/environment.
- `python -c "import app.main"` dari backend menggunakan virtual environment yang terisolasi.
- Tes backend melalui HTTP publik: health DB tersedia/tidak tersedia, request ID, CORS, webhook invalid/missing token, dan respons stub.
- `docker compose config` tanpa mencetak kredensial; build/smoke test backend dan DB bila daemon serta akses dependency tersedia.
- Review independen read-only sesuai aturan multi-file; cari pemanggil produksi untuk seluruh kerangka aktif.
- Verifikasi terpisah atas file hasil, tidak ada `.env` nyata/credential Firebase, dan tidak ada perubahan isi `docs/`.

## Pekerjaan manual dan batas verifikasi

- Manusia membuat project Firebase, menjalankan `flutterfire configure`, serta menyediakan konfigurasi Firebase/OAuth/APNs yang benar.
- Manusia membuat akun Xendit sandbox, menyediakan secrets, dan mengatur webhook publik.
- Manusia mengisi environment deployment dan kredensial PostgreSQL yang aman.
- Build, signing, dan run iOS membutuhkan macOS/Xcode; konfigurasi statis dari Linux tidak membuktikan build iOS berhasil.
- Push dan pembayaran end-to-end tidak dapat dinyatakan teruji dari stub atau tanpa kredensial.
- Tidak mengubah `docs/`; direktori dan dokumen final yang belum tersedia dicatat sebagai belum diberikan.

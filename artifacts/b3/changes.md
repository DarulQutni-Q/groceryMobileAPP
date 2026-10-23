# Perubahan per file B3

Perbandingan sumber dengan commit B2 c727180. Diff pengguna awal pada A3/root/seller tidak dimasukkan.

| File | Alasan |
| --- | --- |
| AGENTS.md | Aturan resolusi path dari pola kegagalan berulang. |
| B3_API.md | Endpoint, curl, konfigurasi test, batas retry dan rekonsiliasi. |
| B3_PLAN.md | Keputusan, acuan visual, dampak dan urutan tes B3. |
| MISTAKES.md | Akar masalah path, rollback SQLite dan finalisasi pembayaran. |
| apps/customer/integration_test/checkout_test.dart | Journey Android dengan backend nyata dari cart sampai COD dan cart kosong. |
| apps/customer/lib/features/catalog/presentation/cart_page.dart | Tombol Checkout membuka konfirmasi hanya untuk item dipilih. |
| apps/customer/lib/features/catalog/presentation/customer_shell.dart | Akses alamat dan resume pembayaran dari Akun, termasuk cart kosong. |
| apps/customer/lib/features/checkout/application/checkout_provider.dart | Provider API/alamat dan status sesi tersimpan. |
| apps/customer/lib/features/checkout/application/checkout_session.dart | Key acak aman, payload dan snapshot per akun sebelum request. |
| apps/customer/lib/features/checkout/presentation/alamat_form_page.dart | Form label/nama/HP/alamat/patokan dengan validasi dan simpan. |
| apps/customer/lib/features/checkout/presentation/alamat_page.dart | Daftar/pilih alamat utama dan edit memakai Material 3. |
| apps/customer/lib/features/checkout/presentation/checkout_page.dart | Alamat/pengiriman/ringkasan/biaya DB dan pembayaran yang dapat dilanjutkan. |
| apps/customer/lib/features/checkout/presentation/checkout_success_page.dart | Sukses COD/paid, kode DG dan navigasi Home/placeholder B4. |
| apps/customer/lib/features/checkout/presentation/metode_bayar_page.dart | Tujuh radio metode pembayaran, QRIS recommended. |
| apps/customer/lib/features/checkout/presentation/payment_page.dart | Browser eksternal, polling 3 detik/2 menit dan retry finalisasi lokal. |
| apps/customer/test/alamat_flow_test.dart | Perjalanan daftar/form/simpan alamat melalui widget. |
| apps/customer/test/checkout_flow_test.dart | COD, polling, expiry, paid storage failure dan resume cart kosong. |
| apps/customer/test/checkout_session_test.dart | Snapshot alamat/catatan/nominal/key dan isolasi akun. |
| apps/customer/test_driver/checkout_test.dart | Simpan screenshot journey ke artifacts/b3. |
| backend/.env.example | Nama variabel Xendit kosong, tanpa kredensial. |
| backend/app/core/config.py | SecretStr untuk kredensial; tolak production key. |
| backend/app/db/migrations/env.py | Daftarkan model baru pada metadata Alembic. |
| backend/app/db/migrations/versions/0005_alamat.py | Buat tabel alamat dan index pemilik. |
| backend/app/db/migrations/versions/0006_checkout_attempt.py | Buat tabel audit checkout sebelum RPC. |
| backend/app/db/migrations/versions/0007_pembayaran.py | Buat tabel pembayaran dan reservasi. |
| backend/app/db/migrations/versions/0008_attempt_outcome.py | Tambah identitas/status outcome dan marker pemulihan attempt. |
| backend/app/db/migrations/versions/0009_payment_reconcile.py | Tambah marker rekonsiliasi dana pada pembayaran. |
| backend/app/main.py | Daftarkan router alamat/checkout/webhook/status pada entry point. |
| backend/app/models/alamat.py | Alamat milik customer, koordinat opsional dan penanda utama. |
| backend/app/models/checkout_attempt.py | Audit kunci/fingerprint dan outcome RPC yang belum terselesaikan. |
| backend/app/models/pembayaran.py | Invoice per order, status dana, reservasi dan penanda rekonsiliasi. |
| backend/app/routers/alamat.py | CRUD dan pergantian alamat utama milik customer. |
| backend/app/routers/pembayaran.py | Preview, checkout, polling, token callback dan limit checkout. |
| backend/app/routers/pesanan.py | Pembacaan pesanan customer sendiri; mutasi seller tetap dibatasi. |
| backend/app/schemas/alamat.py | Batas panjang, HP utuh, koordinat berpasangan dan response alamat. |
| backend/app/schemas/pembayaran.py | Tujuh metode, item unik, total terkonfirmasi, kontrak callback IDR. |
| backend/app/services/alamat.py | Role customer, ownership, row lock user dan alamat utama atomik. |
| backend/app/services/checkout.py | Harga DB, penguncian stok, transaksi utuh dan rekonsiliasi key. |
| backend/app/services/pembayaran.py | Callback idempotent, reservasi sekali dan dana setelah batal. |
| backend/app/services/pesanan.py | Tolak penerimaan non-COD belum paid; pulihkan reservasi saat batal. |
| backend/app/services/xendit.py | HTTP Basic Auth test, timeout, pencarian invoice dan URL tervalidasi. |
| backend/tests/test_alamat.py | Tes HTTP alamat dan validasi pada SQLite/PostgreSQL. |
| backend/tests/test_checkout.py | Harga/stok/rollback/RPC/webhook/rate limit dan konkurensi. |
| backend/tests/test_customer_auth.py | Kontrak baca pesanan customer B3, tetap menguji larangan fitur seller. |
| docker-compose.yml | Teruskan variabel Xendit dari environment host. |
| handoff.md | Status B3 dan pekerjaan sandbox yang masih memerlukan kredensial. |
| packages/shared/lib/shared.dart | Ekspor model/API alamat dan pembayaran. |
| packages/shared/lib/src/api/alamat_api.dart | CRUD alamat melalui ApiClient/JWT yang sudah ada. |
| packages/shared/lib/src/api/checkout_api.dart | Preview/checkout berkey dan polling status pembayaran. |
| packages/shared/lib/src/core/secure_storage.dart | Persistensi sesi checkout terpisah per akun. |
| packages/shared/lib/src/models/alamat.dart | Parse alamat dan snapshot untuk sesi checkout. |
| packages/shared/lib/src/models/pembayaran.dart | Parse pembayaran, hasil checkout dan penanda rekonsiliasi. |
| packages/shared/lib/src/providers/keranjang_provider.dart | Hapus qty pembelian sekali; pertahankan barang lain dan key selesai. |
| packages/shared/test/checkout_api_test.dart | Kontrak alamat dan polling melalui shared client. |
| packages/shared/test/keranjang_test.dart | Pembersihan qty dan deduplikasi setelah restore. |
| scripts/smoke_checkout.py | Smoke HTTP lokal dan akun uji privat, mode sandbox opsional. |
| artifacts/b3/01-form-alamat.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/02-daftar-alamat.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/03-konfirmasi.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/04-metode-bayar.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/05-rincian-cod.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/06-sukses-cod.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/07-keranjang-kosong.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/08-home-apk-normal.png | Screenshot emulator yang diperiksa langsung. |
| artifacts/b3/README.md | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/android-journey.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/backend-tests.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/checks.json | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/compose-build.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/customer-analyze.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/customer-tests.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/git-log.txt | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/http-proof.json | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/http-results.md | Bukti verifikasi, hasil HTTP atau dokumentasi B3; tanpa token/password. |
| artifacts/b3/changes.md | Daftar perubahan dan alasan per file. |

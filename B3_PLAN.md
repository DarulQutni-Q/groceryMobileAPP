# B3: checkout dan pembayaran customer

Sumber: attachment B3, prd.md 3.5, design.md 1.2/4/6 dan rules.md.
Biaya layanan Rp 1.000, ongkir dan diskon nol. Harga selalu dari database;
stok dikunci SELECT FOR UPDATE. Keranjang tetap satu toko seperti B2.
Acuan alamat/konfirmasi: screenshot customer (7)/(11); warna #EFF4EB,
teks/tombol #142618, header hijau, kartu radius 18-20. Komponen Material 3.

## Keputusan dan batas dampak

- Alamat khusus customer, pemeriksaan pemilik pada semua operasi. Perubahan
  alamat utama diserialisasi melalui row user. Alamat pertama menjadi utama.
- Checkout baru membuat pesanan/items/pembayaran dan reservasi stok dalam satu
  transaksi. COD tetap pending sampai pembayaran sungguhan, tetapi langsung
  memperlihatkan sukses pembuatan pesanan. Invoice memakai test key saja.
- Xendit tidak menjamin external_id unik. Catat attempt sebelum RPC, simpan
  fingerprint Idempotency-Key. Timeout ditangani dengan rekonsiliasi GET,
  tidak mengulangi POST invoice secara buta. Attempt audit bukan pesanan;
  kegagalan validasi tidak membuat pesanan atau mengurangi stok.
- Webhook memakai pembandingan token konstan, cocokkan identitas/nominal.
  Pembayaran paid tidak boleh turun status; stok tidak dipotong dua kali.
  Expired/failed dan pembatalan mengembalikan reservasi sekali.
- GET /pesanan customer menampilkan miliknya saja, seller tetap kontrak lama.
  Mutasi seller tetap terlindungi. Pembayaran non-COD pending belum bisa diterima.
- Keranjang baru dibersihkan setelah COD berhasil atau pembayaran paid.
  Retry mempertahankan key dan payload. Polling dibatasi dua menit, berhenti
  saat layar ditutup. Tidak mengerjakan fitur tab pesanan B4 atau voucher.
- Tidak mengedit apps/seller. Patch pengguna disimpan di
  /tmp/b3-preserved-user.patch. Root spesifikasi dan docs pengguna tidak di-stage.

## Seam dan urutan irisan

1. Tes HTTP alamat SQLite/PostgreSQL merah, model/schema/router/migrasi, hijau.
2. Tes checkout HTTP: harga DB, stok/otorisasi/rollback, COD, invoice transport,
   idempotensi dan webhook; layanan/migrasi minimum, regresi seller.
3. Shared model/API dan tes antarmuka; state checkout/alamat dan widget customer.
   Cart Checkout -> Konfirmasi -> alamat/metode -> pembayaran -> sukses.
4. Regresi backend/shared/customer/seller, analyze, build, migrasi dan Android.
   Bukti HTTP/screenshot, panduan sandbox, handoff dan review independen.

Setiap irisan yang diverifikasi langsung di-commit dengan pesan Indonesia.
Kontrak B1 GET /pesanan=403 berubah sengaja menjadi daftar customer milik sendiri;
assertion mutasi dan laporan 403 dipertahankan. Perubahan ini diuji eksplisit.

## Batas verifikasi eksternal

Belum ada kredensial sandbox; pertanyaan penyiapan env sudah dikirim. Tes
transport terkontrol tidak dihitung sebagai pembayaran sandbox nyata. Callback
memerlukan URL HTTPS publik yang dapat dijangkau Xendit. Tidak mengklaim
atomicity lintas gateway dan database; outcome RPC yang tidak diketahui tetap
tercatat untuk rekonsiliasi, tidak dibuat ulang diam-diam.

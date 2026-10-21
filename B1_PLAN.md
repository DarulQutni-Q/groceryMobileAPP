# B1: autentikasi customer GardenMart

Sumber: attachment B1, prd.md bagian3.1, design.md bagian3/4 dan rules.md.
Spesifikasi ada di root; roadmap bertahap tidak ditemukan. Acuan nyata bernama
docs/screenshots/customer/Pasted image.png dan (2),(3),(4), bukan02-auth/03-onboarding.
Empat acuan sudah dilihat. Screen Email Reset Sent belum mempunyai acuan gambar.

## Keputusan dan batas

- Hanya apps/customer, penambahan kompatibel di packages/shared, dan auth backend.
  apps/seller tidak diubah; masalah Chip Toko berada di luar cakupan B1.
- Gunakan Material3: FilledButton, OutlinedButton, TextFormField, Checkbox,
  IconButton, Card dan SnackBar. Artwork/logo memakai potongan ilustrasi acuan,
  bukan gambar utuh yang berpura-pura menjadi form interaktif.
- Warna gambar: splash#96E23B, latar auth#EFF4EB, tombol#142618,
  field#F7F9F5, border#D9E6CF dan CTA lupa sandi#75BF26. Teks mengikuti gambar,
  termasuk judul register Masuk Akun Pembeli dan splash dengan tanda&.
- Email Terkirim mengikuti deskripsi teks B1 dan gaya acuan yang tersedia;
  jangan mengklaim identik dengan gambar yang belum tersedia.
- Endpoint forgot-password tidak ada: Send Email menampilkan Segera hadir,
  tidak mengklaim email sungguhan terkirim. Screen Email Terkirim tetap dibuat
  dan diuji tersendiri; Apple/OTP memakai Segera hadir.
- Konvensi email sintetis tidak dapat menghubungkan nomor HP dengan email asli
  saat pendaftaran. Rekomendasi satu endpoint login-by-phone dengan User.phone.
  Pengguna memilih field HP di form Daftar. UI mengirim nomor asli; backend
  menyimpan format +62 dan menolak nomor yang sudah digunakan.

## Dampak dan ADR auth

Sebelum B1, register/Google seller-only, demikian juga login, me dan refresh.
Mengubah dua schema saja tidak cukup untuk sesi customer. Perlu penyesuaian
kecil di modul auth: register role seller/customer dan admin422, customer tanpa
Toko/JamBuka, login HP, me/refresh customer dan guard seller yang tetap ketat.
User customer memakai nama dari local-part email jika tidak ada field nama.
Tidak menambah model atau migrasi; phone dan role sudah tersedia pada User.

Audience JWT lama tetap dipakai agar kompatibel dengan token seller yang
sudah beredar. Otorisasi customer/seller memakai role akun terkini di DB.
Google subject/email tidak diubah role atau digabung diam-diam jika sudah ada.
Seller client lama tidak mengirim role dan tetap default seller.

Tes A1 yang mengharapkan role admin diabaikan menjadi seller bertentangan
dengan B1 yang secara eksplisit meminta422. Tambah tes penolakan admin dahulu;
perbarui kontrak tes lama secara terang sambil mempertahankan pemeriksaan
default seller dan unique phone. Bukan menghapus tes keamanan untuk meluluskan bug.

## Urutan vertikal dan gate

1. Read-only audit auth/security dan acuan gambar, keputusan alur nomor HP.
2. Tes HTTP customer register/profile/refresh/phone/Google dan isolasi seller,
   lalu implementasi auth minimum. Seluruh regresi backend A5 tetap dijalankan.
3. Shared AuthApi menambah registerCustomer/loginCustomer tanpa mengubah
   method seller; tes payload, role dan penyimpanan sesi melalui client publik.
4. Scaffold customer Android/iOS, flavor dev/staging/prod dan API_BASE_URL dari
   dart-define/env per flavor. Riverpod memakai shared client/secure storage.
5. UI splash/login/register/forgot/email-sent dan Home placeholder saja.
   Session restore, remember-me, logout dan Google mengikuti pola A1 dengan
   pengaman terhadap request lama dan gangguan jaringan.
6. Widget/state tests (validasi, loading, error, navigasi, restore, layout kecil),
   flutter analyze/test customer/shared dan regresi seller tanpa mengedit seller.
7. Build/install/run Android, perjalanan register/phone/restart nyata, screenshot
   lima screen, review independen, dokumen deliverable dan handoff.
8. Pengguna sudah mengizinkan commit B1 dan setiap perubahan kecil berikutnya.
   Commit langsung setelah diverifikasi dengan pesan natural Bahasa Indonesia.
   Aturan tersimpan di AGENTS.md; stage hanya perubahan untuk task tersebut.

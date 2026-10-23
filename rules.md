# Rules — Aturan Kerja AI Agent

Aturan ini WAJIB diikuti di setiap task. Tidak ada pengecualian.

---

## 1. Clean Code, No Over-Engineering

- Tulis kode yang **bersih dan sederhana**. Selesaikan masalah dengan cara paling langsung.
- **Jangan over-engineering.** Jangan buat abstraction, interface, factory, atau pattern yang tidak dibutuhkan sekarang. Kalau cuma dipakai di satu tempat, tulis langsung di situ.
- Jangan bikin "framework mini" di dalam project. Jangan antisipasi kebutuhan masa depan yang belum ada.
- Fungsi maksimal ~30 baris. Kalau lebih, pecah — tapi pecahnya karena alasan nyata, bukan demi pattern.
- Jangan tambah dependency baru kalau bisa selesai dengan yang sudah ada.

## 2. Commit Kecil, Commit Sering

- **Setiap perubahan kecil = 1 commit.** Jangan tumpuk banyak perubahan dalam satu commit.
- Repo sudah di-remote. Push setelah setiap beberapa commit yang logis (atau setiap selesai satu fitur vertikal).
- Commit message:
  - Bahasa Indonesia, natural, seperti manusia nulis. Contoh: `tambah layar login seller`, `benerin validasi OTP`, `rapiin card produk`
  - **JANGAN** pakai format kaku kayak `feat(auth): implement...` atau `fix: resolve issue with...`
  - **JANGAN** pakai em dash (—) di manapun. Tidak di commit message, tidak di dokumentasi, tidak di kode komentar.
  - Satu baris, maksimal ~70 karakter. Kalau perlu penjelasan, tambah body setelah baris kosong.
- Jangan commit file yang tidak perlu (lihat bagian 5).

## 3. Pakai Skills & MCP yang Berguna

- Kamu punya akses penuh. **Pakai skills dan MCP yang relevan** untuk hasil terbaik. Kualitas di atas segalanya (kualitas >> kecepatan).
- Contoh yang wajib dipakai kalau relevan:
  - Skill **anti-ai-slop** — untuk semua output visual dan dokumentasi (lihat bagian 4)
  - MCP database — untuk cek skema, migrasi, query langsung
  - MCP Figma — untuk ambil detail desain yang presisi (warna hex, spacing, font size)
  - MCP GitHub — untuk buat PR, cek CI, kelola issues
- Jangan ragu pakai tools yang ada. Jangan kerja manual kalau ada MCP yang bisa bantu.

## 4. Anti AI Slop

**WAJIB** pakai skill anti-ai-slop untuk semua output. Aturannya:

### Typography & Bahasa
- **JANGAN** pakai em dash (—) dimanapun. Pakai koma, titik, atau tanda hubung biasa (-) kalau perlu.
- Bahasa dokumentasi: natural, tidak kaku. Tulis seperti manusia menjelaskan ke teman.
  - Jelek: "Implementasi modul autentikasi telah diselesaikan dengan mempertimbangkan aspek keamanan."
  - Bagus: "Login sudah jalan. Password di-hash pakai bcrypt, token pakai JWT."
- Jangan pakai kata-kata klise AI: "delve", "moreover", "furthermore", "in today's fast-paced world", "leverage", "seamless", "robust", "cutting-edge".

### Design / UI
- Jangan pakai gradient ungu-biru. Jangan pakai shadow berlebihan.
- Ikuti design system di `docs/design.md` dan screenshot Figma. Jangan improvisasi warna atau style.
- Spacing konsisten. Jangan asal kasih padding/margin beda-beda.
- Tidak ada teks placeholder "Lorem ipsum" di deliverable final.

## 5. .gitignore — Hanya yang Perlu

Buat `.gitignore` yang **minimal dan tepat**. Jangan copy-paste template raksasa.

**Wajib ada:**
```
# Flutter
.dart_tool/
.build/
*.apk
*.aab
*.ipa

# Env & secrets
.env
.env.dev
.env.staging
.env.prod
google-services.json
GoogleService-Info.plist

# Backend
__pycache__/
*.pyc
.venv/
venv/
*.db
*.sqlite3

# OS & editor
.DS_Store
.idea/
.vscode/
```

**Jangan masukkan** hal yang tidak dipakai project ini. Kalau tidak ada file `.ipa`, tidak perlu baris `*.ipa`? Tetap boleh karena Flutter bisa build iOS — pakai akal sehat. Prinsipnya: kalau yakin tidak akan pernah ada file seperti itu di project ini, jangan masukkan.

## 6. Test Sampai Error-Free Sebelum Finalisasi

- **Jangan pernah bilang "selesai" kalau masih ada error.**
- Alur wajib sebelum tandai task selesai:
  1. `flutter analyze` — harus 0 error, 0 warning
  2. `flutter test` (kalau ada test) — semua harus pass
  3. Backend: `python -m py_compile` atau import check — tidak error
  4. `docker compose config` — YAML valid
  5. Jalanin app minimal sampai screen yang dikerjakan kebuka tanpa crash
- Kalau masih error: **kerjakan lagi.** Cari akar masalahnya, jangan tambal. Jangan skip dengan `// ignore:` atau `try/catch` kosong kecuali ada alasan kuat yang ditulis di komentar.
- Jangan pakai `// TODO` sebagai alasan untuk menyerahkan kode setengah jadi. Selesaikan atau bilang terus terang belum bisa.

## 7. Prioritas

Urutannya selalu begini:

1. **Kebenaran** — kode jalan, tidak error, sesuai spec
2. **Kualitas** — bersih, tidak over-engineered, tidak AI slop
3. **Kecepatan** — terakhir. Jangan korbankan 1 dan 2 demi cepat.

---

*Terakhir diupdate: 2026-10-19*

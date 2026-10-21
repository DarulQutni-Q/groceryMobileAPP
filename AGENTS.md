# Aturan proyek tambahan

Ikuti aturan global pengguna serta `rules.md`. Spesifikasi proyek saat ini berada di root: `prd.md`, `design.md`, dan `plan.md`.

Sebelum menerapkan patch setelah formatter, baca ulang blok target saat ini dan cocokkan penanda stabil seperti nama fungsi. Jangan memakai konteks pemenggalan baris dari sebelum formatter. Aturan ini berasal dari tiga kegagalan patch yang dicatat di `MISTAKES.md`.

## Commit setiap perubahan kecil

Pengguna sudah memberi izin untuk langsung commit setiap perubahan kecil yang logis setelah diverifikasi. Jangan menunggu perubahan besar atau meminta konfirmasi commit lagi. Gunakan pesan singkat dan natural dalam Bahasa Indonesia, tanpa prefiks kaku. Stage hanya perubahan yang dikerjakan untuk task tersebut. Instruksi eksplisit terbaru pengguna ini menggantikan aturan umum yang meminta izin commit per tindakan.

Sebelum commit, periksa whitespace semua file yang di-stage, termasuk file vendor dan log baru. Saat menyimpan log tool, hapus padding spasi di ujung baris tanpa mengubah pesan diagnostik. Periksa satu batch lengkap dengan git diff --cached --check agar kegagalan tidak berulang per file. Aturan ini berasal dari tiga kegagalan staging B1 yang dicatat di MISTAKES.md.

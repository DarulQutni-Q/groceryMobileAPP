# Bukti A5

21 Oktober 2026. Backend saja; tidak ada perubahan Flutter dari A5.

| Gate | Hasil |
| --- | --- |
| Seluruh pytest SQLite/PostgreSQL | 138 passed, 0 skipped, 89.19detik |
| HTTP acceptance + Docker prod | 369 kasus, expected=actual seluruhnya, nol500 |
| Login/register/mutasi | Request6/4/61 menghasilkan429 sesuai scope IP/user |
| Health DB aktif/mati | 200/503 dengan komponen dan versi1.0.0 |
| Internal prod, termasuk JSON rusak | 404 sebelum parsing/auth |
| Pagination200 | per_page100, legacy array utuh, filter/ownership benar |
| SQL list20 order/items/customer | Maksimal3 termasuk auth/count; halaman kosong<=3 |
| Multiitem per order | LIMIT berlaku pada parent, total tidak terduplikasi |
| Index migration | Upgrade/downgrade/re-upgrade/check SQLite dan PostgreSQL lulus |
| Migrasi PostgreSQL live | 0004_query_indexes head; tidak ada operasi baru pada check |
| Ruff / compile / Compose config | Lulus |
| Image backend | Dibangun dan berjalan, hash45file app sama dengan host |
| Log runtime | JSON ke stderr, marker query/password/JWT tidak tercetak |
| Review independen | Query/index dan security, seluruh P1/P2 temuan ditutup |
| Cleanup | Container/schema runtime uji dibersihkan; layanan utama sehat ENVdev |

Lihat endpoint-matrix.md atau endpoint-matrix.csv untuk tabel endpoint, input,
expected dan actual. runtime-matrix.json berisi79pemeriksaan Docker sebenarnya;
junit.xml memuat138tes. summary.json memuat ringkasan yang dapat dibaca mesin.
Contoh curl, alasan perubahan per file, pengecualian dan cara rerun ada di A5_API.md.

Tes fault injection sengaja menghasilkan500 dan traceback untuk membuktikan
fallback; tidak termasuk matriks369input acceptance. Bukti ini tidak menjamin
semua input yang mungkin atau performa beban produksi. Redis aktif multiworker,
payment/webhook yang belum dibangun dan deployment internet belum diverifikasi.
Build memakai Docker classic builder karena plugin buildx tidak terpasang.

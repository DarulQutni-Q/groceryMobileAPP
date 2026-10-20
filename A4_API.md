# API laporan seller A4

Semua endpoint memakai JWT seller. Toko selalu ditentukan dari pemilik sesi, tanpa menerima toko_id dari klien.

| Metode | Path | Query |
| --- | --- | --- |
| GET | /laporan/ringkasan | range=7h atau 30h, default 7h |
| GET | /laporan/produk-terlaris | range=7h atau 30h; limit integer 1-100, default 5 |

Contoh, setelah variabel TOKEN berisi access token lokal:

```bash
curl --fail-with-body --get 'http://127.0.0.1:8000/laporan/ringkasan' \
  --data-urlencode 'range=7h' --header "Authorization: Bearer $TOKEN"
curl --fail-with-body --get 'http://127.0.0.1:8000/laporan/produk-terlaris' \
  --data-urlencode 'range=30h' --data-urlencode 'limit=5' \
  --header "Authorization: Bearer $TOKEN"
```

Ringkasan mengembalikan total_penjualan, jumlah_pesanan, jumlah_produk_terjual, perbandingan_minggu_lalu, ada_pembanding, dan penjualan_per_hari berisi tanggal ISO serta total. Ranking berisi produk_id, nama, foto_url, total_qty dan total_rupiah. Angka rupiah berupa integer.

Hanya status selesai dihitung. Tanggal memakai waktu selesai updated_at, dengan batas kalender WIB termasuk hari ini. Rentang tujuh hari dibanding tujuh hari sebelumnya; rentang 30 dibanding 30 sebelumnya. Nama field perbandingan_minggu_lalu dipertahankan untuk keduanya. Jika baseline nol, persentase nol dan ada_pembanding=false; UI menampilkan Belum ada pembanding.

Jika tidak ada pesanan selesai pada rentang aktif, total/count/qty nol dan array harian/ranking kosong. Pesanan berdiskon penuh tetap dihitung meskipun total nol. Jika ada pesanan, array harian mempunyai tepat 7/30 hari, termasuk hari tanpa transaksi dengan total nol.

Ringkasan memakai CTE dan agregat SQL dalam satu statement, sehingga total, count, qty dan grafik melihat snapshot transaksi yang sama. Agregat qty dihitung per pesanan sebelum digabung, agar total order multi-item tidak berlipat. Ranking memakai SUM dan GROUP BY, urut qty menurun, rupiah menurun lalu nama/ID sebagai pemecah seri.

Total penjualan menjumlah total akhir pesanan termasuk ongkir/biaya dan diskon. Total rupiah produk terlaris adalah nilai bruto harga_snapshot * qty. Nama/foto produk aktif mengikuti katalog saat ini. Produk dihapus tetap dihitung memakai nama_snapshot, dengan ID/foto null. Dua produk terhapus bernama sama tidak dapat dipisahkan dari snapshot A3 yang tersisa.

Tanpa JWT menghasilkan 401; role selain seller 403. Rentang atau limit tidak valid menghasilkan 422 dengan pesan validasi Indonesia. Endpoint dummy pesanan tetap khusus ENV=dev. Tidak ada migrasi A4; head tetap 0003_pesanan.

Acceptance yang sudah dijalankan:

```bash
python3 scripts/smoke_laporan.py --base-url http://127.0.0.1:8000
```

Skrip menjalankan curl tanpa mencetak token/password: toko kosong menghasilkan nol, tiga pesanan selesai menghasilkan Rp 135.000, 9 barang dan ranking qty 6/3, serta seller lain tetap kosong. Pengujian HTTP juga mencakup batas WIB, status campuran, 30 hari, pembanding, penghapusan produk dan transaksi serentak di PostgreSQL.

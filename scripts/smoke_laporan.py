import argparse
import secrets
import uuid

from smoke_auth import request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', required=True)
    base = parser.parse_args().base_url.rstrip('/')
    account = {'nama_pemilik': 'Pemilik Uji A4', 'nama_toko': 'Toko Laporan A4',
               'email': f'a4-{uuid.uuid4().hex}@example.com',
               'password': secrets.token_urlsafe(10) + 'A1!'}
    token = request(base, 'POST', '/auth/register', 200, account)['access_token']
    path = '/laporan/ringkasan?range=7h'
    empty = request(base, 'GET', path, 200, token=token)
    assert empty['total_penjualan'] == empty['jumlah_pesanan'] == 0
    assert empty['penjualan_per_hari'] == []
    assert request(base, 'GET', '/laporan/produk-terlaris', 200, token=token) == []
    products = [request(base, 'POST', '/produk', 200, {
        'nama': f'Produk A4 {i}', 'harga': i * 10000, 'stok': 50,
        'satuan': 'pcs', 'kategori': 'Sembako'}, token) for i in (1, 2)]
    totals = []
    for qty in (1, 2, 3):
        order = request(base, 'POST', '/pesanan/internal/test', 200, {
            'items': [{'produk_id': products[0]['id'], 'qty': qty},
                      {'produk_id': products[1]['id'], 'qty': 1}],
            'alamat_kirim': 'Jalan Laporan A4', 'ongkir': 5000}, token)
        totals.append(order['total'])
        resource = '/pesanan/' + order['id']
        request(base, 'PATCH', resource + '/terima', 200, token=token)
        for status in ('dikemas', 'diantar', 'selesai'):
            request(base, 'PATCH', resource + '/status', 200, {'status': status}, token)
    report = request(base, 'GET', path, 200, token=token)
    assert report['total_penjualan'] == sum(totals) == 135000
    assert report['jumlah_pesanan'] == 3 and report['jumlah_produk_terjual'] == 9
    assert len(report['penjualan_per_hari']) == 7
    assert sum(day['total'] for day in report['penjualan_per_hari']) == 135000
    ranking = request(base, 'GET', '/laporan/produk-terlaris?range=7h&limit=5', 200, token=token)
    assert [p['total_qty'] for p in ranking] == [6, 3]
    assert [p['total_rupiah'] for p in ranking] == [60000, 60000]
    request(base, 'GET', path, 401)
    request(base, 'GET', '/laporan/ringkasan?range=1h', 422, token=token)
    account['email'] = f'other-a4-{uuid.uuid4().hex}@example.com'
    other = request(base, 'POST', '/auth/register', 200, account)['access_token']
    assert request(base, 'GET', path, 200, token=other)['total_penjualan'] == 0
    assert request(base, 'GET', '/laporan/produk-terlaris', 200, token=other) == []
    print('PASS A4 curl: empty 0, tiga selesai Rp 135.000, qty 9, ranking 6/3, ownership.')


if __name__ == '__main__':
    main()

import argparse
import json
import os
import secrets
import time
import urllib.error
import urllib.request
from pathlib import Path
from uuid import uuid4


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', required=True)
    parser.add_argument('--proof-file', required=True)
    parser.add_argument('--session-file', required=True)
    args = parser.parse_args()
    rows = []

    def call(method, path, expected=200, data=None, token=None):
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        request = urllib.request.Request(args.base_url.rstrip('/') + path,
            data=None if data is None else json.dumps(data).encode(), headers=headers, method=method)
        try:
            response = urllib.request.urlopen(request, timeout=20)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            status = response.status
            body = json.load(response)
        rows.append({'method': method, 'path': path, 'expected': expected, 'actual': status})
        assert status == expected, f'{method} {path}: expected {expected}, actual {status}'
        return body

    suffix = str(int(time.time()))
    password = secrets.token_urlsafe(9) + 'A1!'
    call('GET', '/health')
    seller = call('POST', '/auth/register', data={'role': 'seller', 'nama_pemilik': 'Penjual Uji B2',
        'nama_toko': 'Toko Diponegoro B2', 'email': f'b2seller{suffix}@example.com', 'password': password})['access_token']
    phone = '081' + suffix[-9:]
    email = f'b2buyer{suffix}@example.com'
    customer = call('POST', '/auth/register', data={'role': 'customer', 'email': email,
        'phone': phone, 'password': password})['access_token']
    store = call('PUT', '/toko/me', data={'nama': 'Toko Diponegoro B2', 'alamat': 'Jl. Diponegoro 42',
        'telepon': '081234567890', 'rekening_bank': 'BANK-PRIVATE-B2'}, token=seller)
    store_id = store['id']
    call('PUT', '/toko/me/jam-buka', data=[{'hari': day, 'is_tutup': False, 'jam_buka': '08:00:00',
        'jam_tutup': '23:00:00'} for day in ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu']], token=seller)
    call('PATCH', '/toko/me/status', data={'status': 'buka'}, token=seller)
    products = []
    seeds = [('Indomie Spesial Isi 5', 16200, 25, 'pcs', 'Mie'), ('Ultra Milk UHT Cokelat', 17500, 14, 'liter', 'Susu'),
        ('Bimoli Minyak Goreng 2L', 33900, 5, 'liter', 'Minyak')] + [
        (f'Beras Pilihan {n+1}', 15000 + n * 1000, 10, 'kg', 'Beras') for n in range(10)]
    for name, price, stock, unit, category in seeds:
        products.append(call('POST', '/produk', data={'nama': name, 'harga': price, 'stok': stock,
            'satuan': unit, 'kategori': category}, token=seller))
    hidden = call('POST', '/produk', data={'nama': 'Produk disembunyikan', 'harga': 1000, 'stok': 0,
        'satuan': 'pcs', 'kategori': 'Internal'}, token=seller)
    call('PATCH', '/produk/' + hidden['id'] + '/toggle', token=seller)
    query = f'toko_id={store_id}'
    found = call('GET', '/produk?q=indomie&' + query, token=customer)
    assert [p['id'] for p in found['data']] == [products[0]['id']]
    found = call('GET', '/produk?kategori=Beras&' + query, token=customer)
    assert len(found['data']) == 10 and all(p['kategori'] == 'Beras' for p in found['data'])
    found = call('GET', '/produk?page=2&per_page=5&' + query, token=customer)
    assert len(found['data']) == 5 and found['meta'] == {'page': 2, 'per_page': 5, 'total': 13, 'total_pages': 3}
    assert call('GET', '/produk?per_page=200&' + query, token=customer)['meta']['per_page'] == 100
    assert call('GET', '/produk/' + products[0]['id'], token=customer)['nama'] == seeds[0][0]
    call('GET', '/produk/' + hidden['id'], 404, token=customer)
    assert isinstance(call('GET', '/produk', token=seller), list)
    stores = call('GET', '/toko', token=customer)
    assert any(t['id'] == store_id for t in stores['data'])
    assert all('owner_id' not in t and 'rekening_bank' not in t for t in stores['data'])
    detail = call('GET', f'/toko/{store_id}?per_page=5', token=customer)
    assert len(detail['produk']) == 5 and detail['jam_tutup'] == '23:00:00'
    assert 'owner_id' not in detail and 'rekening_bank' not in detail
    assert {'Mie', 'Beras', 'Susu', 'Minyak'} <= set(call('GET', '/kategori', token=customer))
    assert call('GET', '/promo', token=customer)[0]['is_demo'] is True
    for path in ['/produk', '/toko', '/kategori', '/promo']:
        call('GET', path, 401)
    for path in ['/produk?page=0', '/produk?per_page=-1', '/produk/not-uuid', '/toko/not-uuid', '/produk?q=%00']:
        call('GET', path, 422, token=customer)
    call('GET', '/produk/' + str(uuid4()), 404, token=customer)
    call('POST', '/produk', 403, data={'nama': 'Tidak boleh', 'harga': 1000, 'stok': 1, 'satuan': 'pcs', 'kategori': 'Mie'}, token=customer)
    call('PATCH', '/produk/' + products[0]['id'] + '/toggle', 403, token=customer)
    call('PATCH', '/toko/me/status', 403, data={'status': 'tutup'}, token=customer)
    call('PATCH', '/toko/me/status', data={'status': 'tutup'}, token=seller)
    call('GET', '/toko/' + store_id, 404, token=customer)
    assert call('GET', '/produk?' + query, token=customer)['data'] == []
    call('PATCH', '/toko/me/status', data={'status': 'buka'}, token=seller)
    session = {'email': email, 'phone': phone, 'password': password, 'token': customer,
        'seller_token': seller, 'store_id': store_id, 'product_ids': [p['id'] for p in products]}
    descriptor = os.open(args.session_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, 'w') as file:
        json.dump(session, file)
    proof = {'requests': rows, 'checks': 'search/category/page2/limit/privacy/hours/auth/ownership/closed-store',
        'server_errors': sum(row['actual'] >= 500 for row in rows)}
    Path(args.proof_file).write_text(json.dumps(proof, indent=2) + '\n')
    print(f'PASS {len(rows)} live HTTP requests, {proof["server_errors"]} server errors; private credentials saved outside repository')


if __name__ == '__main__':
    main()

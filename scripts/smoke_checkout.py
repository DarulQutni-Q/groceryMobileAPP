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
    parser.add_argument('--sandbox', action='store_true')
    args = parser.parse_args()
    rows = []

    def call(method, path, expected=200, data=None, token=None, extra=None, raw=None):
        headers = {'Content-Type': 'application/json', **(extra or {})}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        body = raw if raw is not None else None if data is None else json.dumps(data).encode()
        request = urllib.request.Request(args.base_url.rstrip('/') + path,
            data=body, headers=headers, method=method)
        try:
            response = urllib.request.urlopen(request, timeout=30)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            status = response.status
            content = response.read()
            value = json.loads(content) if content else None
        rows.append({'method': method, 'path': path, 'expected': expected, 'actual': status})
        assert status == expected, f'{method} {path}: expected {expected}, actual {status}'
        return value

    suffix = str(int(time.time()))
    password = secrets.token_urlsafe(12) + 'A1!'
    users = []
    phone = '082' + suffix[-9:]
    call('GET', '/health')
    for role, name in [('seller', 'seller'), ('customer', 'buyer'), ('customer', 'other')]:
        payload = {'role': role, 'email': f'b3{name}{suffix}@example.com', 'password': password}
        if role == 'seller':
            payload.update(nama_pemilik='Penjual B3', nama_toko='Toko B3')
        if name == 'buyer':
            payload['phone'] = phone
        users.append(call('POST', '/auth/register', data=payload)['access_token'])
    seller, buyer, other = users
    call('PATCH', '/toko/me/status', token=seller, data={'status': 'buka'})
    products = [call('POST', '/produk', token=seller, data={'nama': name, 'harga': price,
        'stok': 20, 'satuan': 'pcs', 'kategori': 'Sembako'})
        for name, price in [('B3 Beras Pilihan', 15000), ('B3 Telur Segar', 2000)]]
    address_body = {'label': 'Rumah', 'nama_penerima': 'Pembeli B3', 'no_hp': phone,
        'alamat_lengkap': 'Jalan Melati 10', 'patokan': 'Pagar hijau'}
    address = call('POST', '/alamat', 201, token=buyer, data=address_body)
    second = call('POST', '/alamat', 201, token=buyer, data={**address_body, 'label': 'Kantor'})
    call('GET', '/alamat', token=buyer)
    assert call('GET', '/alamat', token=other) == []
    call('PUT', '/alamat/' + second['id'], token=buyer,
        data={**address_body, 'label': 'Kantor', 'alamat_lengkap': 'Jalan Kantor 20'})
    call('PATCH', f"/alamat/{second['id']}/jadikan-utama", token=buyer)
    call('PATCH', f"/alamat/{address['id']}/jadikan-utama", token=buyer)
    for method, tail in [('PUT', ''), ('DELETE', ''), ('PATCH', '/jadikan-utama')]:
        call(method, '/alamat/' + address['id'] + tail, 403, token=other,
             data=address_body if method == 'PUT' else None)
    call('DELETE', '/alamat/' + second['id'], 204, token=buyer)
    body = {'alamat_id': address['id'], 'metode_kirim': 'Instant', 'metode_bayar': 'cod',
        'items': [{'produk_id': p['id'], 'qty': 1} for p in products]}
    call('POST', '/checkout', 403, token=other, data=body)
    excess = {**body, 'items': [{'produk_id': products[0]['id'], 'qty': 21}]}
    call('POST', '/checkout', 400, token=buyer, data=excess)
    assert call('GET', '/pesanan', token=buyer)['data'] == []
    call('POST', '/checkout', 422, token=buyer, data={**body, 'total': 1})
    call('POST', '/checkout', 422, token=buyer, raw=b'{bad')
    call('POST', '/checkout', 422, token=buyer, data={**body, 'alamat_id': 'not-uuid'})
    preview = call('POST', '/checkout/preview', token=buyer, data=body)
    assert preview['subtotal'] == 17000 and preview['total'] == 18000
    invoice = call('POST', '/checkout', 201 if args.sandbox else 503, token=buyer,
        data={**body, 'metode_bayar': 'qris'})
    if args.sandbox:
        assert invoice['payment_url'].startswith('https://')
    key = f'{int(time.time() * 1000)}-{uuid4().hex}'
    result = call('POST', '/checkout', 201, token=buyer, data=body,
                  extra={'Idempotency-Key': key})
    retry = call('POST', '/checkout', 201, token=buyer, data=body,
                 extra={'Idempotency-Key': key})
    assert result['pesanan']['id'] == retry['pesanan']['id']
    payment_id, order_id = result['pembayaran']['id'], result['pesanan']['id']
    assert call('GET', f'/pembayaran/{payment_id}/status', token=buyer)['status'] == 'pending'
    call('GET', f'/pembayaran/{payment_id}/status', 403, token=other)
    call('GET', f'/pesanan/{order_id}', token=buyer)
    call('GET', f'/pesanan/{order_id}', 404, token=other)
    call('POST', '/webhook/xendit', 403, data={'id': 'unknown', 'external_id': 'unknown',
        'status': 'PAID', 'amount': 18000})
    for path in ['/alamat', f'/pembayaran/{payment_id}/status']:
        call('GET', path, 401)
    call('POST', '/checkout', 401, data=body)
    private = {'phone': phone, 'password': password, 'product_ids': [p['id'] for p in products],
        'token': buyer, 'seller_token': seller, 'address_id': address['id'],
        'B3_ACCOUNT': phone, 'B3_PASSWORD': password,
        'B3_PRODUCT_1': products[0]['id'], 'B3_PRODUCT_2': products[1]['id']}
    descriptor = os.open(args.session_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    os.fchmod(descriptor, 0o600)
    with os.fdopen(descriptor, 'w') as file:
        json.dump(private, file)
    proof = {'requests': rows, 'errors_500': sum(row['actual'] == 500 for row in rows),
        'qris': 'sandbox invoice created, payment not simulated' if args.sandbox else '503 expected: sandbox key absent',
        'callback': 'unsigned rejected; signed PAID covered by controlled transport HTTP tests'}
    Path(args.proof_file).write_text(json.dumps(proof, indent=2) + '\n')
    print(f'PASS {len(rows)} live requests; {proof["errors_500"]} responses 500; QRIS real: {args.sandbox}')


if __name__ == '__main__':
    main()

import argparse
import hashlib
import json
import secrets
import struct
import subprocess
import tempfile
import uuid
import zlib
from pathlib import Path

from smoke_auth import request


def png():
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', 16, 16, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\x00' + b'\x20\x80\x40' * 16) * 16))
            + chunk(b'IEND', b''))


def upload(base, path, token, file, expected):
    config = [f'url = {json.dumps(base + path + "/foto")}', 'request = "POST"',
              f'header = {json.dumps("Authorization: Bearer " + token)}',
              f'form = {json.dumps("file=@" + str(file) + ";type=image/png;filename=photo.png")}']
    result = subprocess.run(['curl', '--silent', '--show-error', '--max-time', '20',
                             '--config', '-', '--write-out', '\n%{http_code}'],
                            input='\n'.join(config), capture_output=True, text=True, check=True)
    body, status = result.stdout.rsplit('\n', 1)
    assert int(status) == expected, f'Upload expected {expected}, got {status}'
    print(f'PASS POST /produk/{{id}}/foto: {status}')
    return json.loads(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', required=True)
    parser.add_argument('--proof-file')
    args = parser.parse_args()
    base = args.base_url.rstrip('/')
    account = {'nama_pemilik': 'Pemilik Uji A2', 'nama_toko': 'Toko Uji A2',
               'email': f'a2-{uuid.uuid4().hex}@example.com', 'password': secrets.token_urlsafe(9) + 'A1!'}
    token = request(base, 'POST', '/auth/register', 200, account)['access_token']
    request(base, 'GET', '/toko/me', 401)
    toko = request(base, 'GET', '/toko/me', 200, token=token)
    assert toko['status'] == 'tutup' and toko['radius_km'] == 5
    request(base, 'PUT', '/toko/me', 200, {'nama': 'Toko A2 Tersimpan', 'alamat': 'Jalan Uji 20',
        'telepon': '081234567890', 'kategori': ['Sembako'], 'metode_kirim': ['Instant'],
        'radius_km': 7, 'rekening_bank': 'BRI 1234567890'}, token)
    assert request(base, 'GET', '/auth/me', 200, token=token)['nama_toko'] == 'Toko A2 Tersimpan'
    request(base, 'PATCH', '/toko/me/status', 200, {'status': 'buka'}, token)
    days = request(base, 'GET', '/toko/me/jam-buka', 200, token=token)
    assert len(days) == 7
    days[0].update(is_tutup=False, jam_buka='07:00:00', jam_tutup='23:00:00')
    request(base, 'PUT', '/toko/me/jam-buka', 200, days, token)
    request(base, 'PUT', '/toko/me/jam-buka', 422, days[:-1], token)
    data = {'nama': 'Beras Uji A2', 'harga': 15000, 'stok': 4, 'satuan': 'kg', 'kategori': 'Beras'}
    product = request(base, 'POST', '/produk', 200, data, token)
    path = '/produk/' + product['id']
    request(base, 'POST', '/produk', 422, {**data, 'harga': 0}, token)
    request(base, 'POST', '/produk', 422, {**data, 'stok': -1}, token)
    request(base, 'POST', '/produk', 422, {**data, 'satuan': 'gram'}, token)
    found = request(base, 'GET', '/produk?q=beras&kategori=Beras', 200, token=token)
    assert [item['id'] for item in found] == [product['id']]
    request(base, 'GET', path, 200, token=token)
    request(base, 'PUT', path, 200, {'stok': 0}, token)
    assert request(base, 'PATCH', path + '/toggle', 200, token=token)['is_tersedia'] is False
    account['email'] = f'other-{uuid.uuid4().hex}@example.com'
    other = request(base, 'POST', '/auth/register', 200, account)['access_token']
    request(base, 'GET', path, 404, token=other)
    request(base, 'PUT', path, 404, {'stok': 9}, other)
    request(base, 'PATCH', path + '/toggle', 404, token=other)
    with tempfile.TemporaryDirectory(prefix='grocery-a2-') as folder:
        file = Path(folder) / 'photo.png'
        file.write_bytes(png())
        uploaded = upload(base, path, token, file, 200)
        upload(base, path, other, file, 404)
        file.write_bytes(b'not a photo')
        upload(base, path, token, file, 422)
        file.write_bytes(png() + b'0' * (5 * 1024 * 1024))
        upload(base, path, token, file, 422)
    if args.proof_file:
        Path(args.proof_file).write_text(json.dumps({'foto_url': uploaded['foto_url'],
            'sha256': hashlib.sha256(png()).hexdigest()}))
    else:
        request(base, 'DELETE', path, 200, token=token)
        request(base, 'GET', path, 404, token=token)
    disposable = request(base, 'POST', '/produk', 200, data, token)
    request(base, 'DELETE', '/produk/' + disposable['id'], 200, token=token)
    print('PASS A2 acceptance curl: credentials never printed')


if __name__ == '__main__':
    main()

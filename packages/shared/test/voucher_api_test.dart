import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

Map<String, dynamic> sampleVoucher(String kode) => {
  'id': 'v-$kode',
  'toko_id': 't1',
  'kode': kode,
  'judul': 'Judul $kode',
  'jenis': 'persen',
  'persen': 30,
  'cap': 25000,
  'min_belanja': 75000,
  'max_ongkir': 0,
  'aktif': true,
  'created_at': '2026-11-02T00:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test('voucher API memakai path backend dan model menghitung potongan', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final calls = <String>[];
    dio.httpClientAdapter = TestAdapter((request) async {
      calls.add('${request.method} ${request.path}');
      if (request.path == '/voucher/toko/t1') {
        return jsonBody([sampleVoucher('HEMAT30')], 200);
      }
      if (request.path == '/voucher' && request.method == 'POST') {
        return jsonBody(sampleVoucher('BARU'), 201);
      }
      if (request.path == '/voucher/v-HEMAT30' && request.method == 'PATCH') {
        final row = sampleVoucher('HEMAT30')..['aktif'] = false;
        return jsonBody(row, 200);
      }
      if (request.path == '/voucher/v-HEMAT30' && request.method == 'DELETE') {
        return jsonBody({}, 204);
      }
      return jsonBody({'detail': 'Tidak ditemukan'}, 404);
    });
    final api = VoucherApi(
      ApiClient(baseUrl: 'https://api.example.com', storage: SecureStorage(), dio: dio),
    );

    final vouchers = await api.listToko('t1');
    expect(vouchers, hasLength(1));
    final voucher = vouchers.first;
    expect(voucher.kode, 'HEMAT30');
    expect(voucher.potonganTagihan(100000), 25000);
    expect(voucher.potonganTagihan(50000), 0);
    expect(voucher.memenuhiSyarat(75000), isTrue);
    expect(voucher.memenuhiSyarat(74999), isFalse);

    final created = await api.create({'kode': 'BARU', 'judul': 'Baru'});
    expect(created.kode, 'BARU');
    final off = await api.setAktif('v-HEMAT30', false);
    expect(off.aktif, isFalse);
    await api.delete('v-HEMAT30');

    expect(calls, [
      'GET /voucher/toko/t1',
      'POST /voucher',
      'PATCH /voucher/v-HEMAT30',
      'DELETE /voucher/v-HEMAT30',
    ]);
  });

  test('potongan ongkir dibatasi max_ongkir dan tanpa voucher netral', () {
    final gratis = Voucher(
      id: 'v2',
      tokoId: 't1',
      kode: 'GRATIS',
      judul: 'Gratis ongkir',
      jenis: 'gratis_ongkir',
      maxOngkir: 15000,
    );
    expect(gratis.potonganOngkir(10000), 10000);
    expect(gratis.potonganOngkir(20000), 15000);
    expect(gratis.potonganTagihan(100000), 0);
    expect(Voucher.tanpa.isTanpa, isTrue);
    expect(Voucher.tanpa.potonganTagihan(100000), 0);
  });
}

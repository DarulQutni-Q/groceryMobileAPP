import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'store_fixture.dart';

Map<String, dynamic> orderFixture(String id, String code, String status) => {
  'id': id,
  'kode': code,
  'status': status,
  'alamat_kirim': 'Jalan Uji 3',
  'catatan': 'Titip di depan',
  'metode_kirim': 'Instant',
  'slot_waktu': 'Hari ini 15.00-17.00',
  'subtotal': 30000,
  'diskon': 1000,
  'ongkir': 5000,
  'biaya_layanan': 500,
  'total': 34500,
  'tolak_alasan': status == 'ditolak' ? 'Stok Habis' : null,
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'server_time': DateTime.now().toUtc().toIso8601String(),
  'undo_until': null,
  'nama_pembeli': null,
  'telepon_pembeli': null,
  'items': [
    {
      'produk_id': 'p1',
      'nama_snapshot': 'Beras Uji',
      'harga_snapshot': 15000,
      'qty': 2,
    },
  ],
};

class PesananFixture extends StoreFixture {
  bool failList = false;
  bool failDetail = false;
  bool changed = false;
  Completer<void>? listGate, undoGate;
  final orders = [
    orderFixture('o1', 'DG-11111', 'baru'),
    orderFixture('o2', 'DG-22222', 'diproses'),
    orderFixture('o3', 'DG-33333', 'ditolak'),
  ];
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    Object? data;
    var code = 200;
    if (request.path == '/pesanan') {
      if (changed && listGate != null) await listGate!.future;
      data = failList ? {'detail': 'Pesanan belum dapat dimuat'} : orders;
      if (failList) code = 503;
    } else if (request.path.startsWith('/pesanan/')) {
      final order = orders.firstWhere(
        (o) => o['id'] == request.path.split('/')[2],
      );
      if (request.method == 'PATCH') {
        changed = true;
        final action = request.path.split('/').last;
        if (action == 'urungkan' && undoGate != null) await undoGate!.future;
        order['status'] = switch (action) {
          'terima' => 'diproses',
          'tolak' => 'ditolak',
          'urungkan' => 'baru',
          _ => (request.data as Map)['status'],
        };
        if (action == 'tolak') {
          order['tolak_alasan'] = (request.data as Map)['alasan'];
        }
        final now = DateTime.now().toUtc();
        order['server_time'] = now.toIso8601String();
        order['undo_until'] = action == 'terima'
            ? now.add(const Duration(seconds: 10)).toIso8601String()
            : null;
      }
      data = order;
      if (request.method == 'GET' && failDetail) {
        data = {'detail': 'Detail pesanan belum dapat dimuat'};
        code = 503;
      }
    } else {
      return super.fetch(request, stream, cancelFuture);
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

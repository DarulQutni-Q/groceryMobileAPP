import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'pesanan_fixture.dart';

class LaporanFixture extends PesananFixture {
  bool empty = false, fail = false;
  Completer<void>? gate;
  String? blockedRange;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (!request.path.startsWith('/laporan/')) {
      return super.fetch(request, stream, cancelFuture);
    }
    requests.add(request);
    final range = request.queryParameters['range'] as String;
    if (blockedRange == null || blockedRange == range) await gate?.future;
    final count = range == '7h' ? 7 : 30;
    final total = range == '7h' ? 124000 : 248000;
    final data = request.path.endsWith('ringkasan')
        ? {
            'total_penjualan': empty ? 0 : total,
            'jumlah_pesanan': empty ? 0 : 3,
            'jumlah_produk_terjual': empty ? 0 : 7,
            'perbandingan_minggu_lalu': range == '7h' ? 10.5 : -3.5,
            'ada_pembanding': !empty,
            'penjualan_per_hari': empty
                ? []
                : [
                    for (var i = 0; i < count; i++)
                      {
                        'tanggal': DateTime(2026, 10, 20)
                            .subtract(Duration(days: count - i - 1))
                            .toIso8601String()
                            .substring(0, 10),
                        'total': i == count - 1 ? total : 0,
                      },
                  ],
          }
        : empty
        ? []
        : [
            for (var i = 0; i < (request.queryParameters['limit'] as int); i++)
              {
                'produk_id': i == 0 ? null : 'p$i',
                'nama': 'Beras ${i + 1}',
                'foto_url': null,
                'total_qty': 6 - i,
                'total_rupiah': (6 - i) * 15000,
              },
          ];
    return ResponseBody.fromString(
      jsonEncode(fail ? {'detail': 'Laporan belum dapat dimuat'} : data),
      fail ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

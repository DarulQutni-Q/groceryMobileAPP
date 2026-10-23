import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class StoreFixture implements HttpClientAdapter {
  bool failDelete = false;
  bool failRefreshAfterDelete = false;
  bool failProductList = false;
  bool failLogoUpload = false;
  final profile = <String, dynamic>{
    'id': 't1',
    'nama': 'Toko Uji',
    'alamat': 'Jalan Uji',
    'telepon': '081234567890',
    'kategori': ['Sembako'],
    'radius_km': 5,
    'status': 'tutup',
    'metode_kirim': ['Instant'],
  };
  final products = <Map<String, dynamic>>[
    {
      'id': 'p1',
      'toko_id': 't1',
      'nama': 'Beras Uji',
      'harga': 15000,
      'stok': 4,
      'satuan': 'kg',
      'kategori': 'Beras',
      'is_tersedia': true,
    },
  ];
  List<Map<String, dynamic>> hours = [
    for (final hari in [
      'senin',
      'selasa',
      'rabu',
      'kamis',
      'jumat',
      'sabtu',
      'minggu',
    ])
      {'hari': hari, 'is_tutup': true, 'jam_buka': null, 'jam_tutup': null},
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (request.path == '/produk' &&
        request.method == 'GET' &&
        failProductList) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'Daftar produk belum dapat dimuat'}),
        503,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (request.method == 'DELETE' && failDelete) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'Produk belum bisa dihapus'}),
        503,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    Object data = profile;
    if (request.path == '/auth/me') {
      data = {
        'id': 'u1',
        'nama': 'Pemilik Uji',
        'email': 'uji@example.com',
        'role': 'seller',
        'nama_toko': 'Toko Uji',
      };
    } else if (request.path == '/pesanan') {
      data = <Object>[];
    } else if (request.path == '/laporan/ringkasan') {
      data = {
        'total_penjualan': 0,
        'jumlah_pesanan': 0,
        'jumlah_produk_terjual': 0,
        'perbandingan_minggu_lalu': 0,
        'penjualan_per_hari': [],
      };
    } else if (request.path == '/laporan/produk-terlaris') {
      data = <Object>[];
    } else if (request.path == '/toko/me/jam-buka') {
      if (request.method == 'PUT') {
        hours = List<Map<String, dynamic>>.from(request.data as List);
      }
      data = hours;
    } else if (request.path == '/toko/me/logo') {
      if (failLogoUpload) {
        return ResponseBody.fromString(
          jsonEncode({'detail': 'Gagal mengunggah logo'}),
          400,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      profile['logo_url'] = '/uploads/logo-toko.png';
      data = profile;
    } else if (request.path.startsWith('/toko/me')) {
      if (request.data is Map) {
        profile.addAll(Map<String, dynamic>.from(request.data as Map));
      }
    } else if (request.path == '/produk') {
      if (request.method == 'POST') {
        products.add({
          ...Map<String, dynamic>.from(request.data as Map),
          'id': 'p2',
          'toko_id': 't1',
          'is_tersedia': true,
        });
        data = products.last;
      } else {
        final q = (request.queryParameters['q'] as String? ?? '').toLowerCase();
        final kategori = request.queryParameters['kategori'] as String? ?? '';
        data = products
            .where(
              (p) =>
                  (p['nama'] as String).toLowerCase().contains(q) &&
                  (kategori.isEmpty || p['kategori'] == kategori),
            )
            .toList();
      }
    } else if (request.path.startsWith('/produk/')) {
      final product = products.firstWhere(
        (p) => request.path.contains(p['id'] as String),
      );
      if (request.path.endsWith('/toggle')) {
        product['is_tersedia'] = !(product['is_tersedia'] as bool);
      }
      if (request.method == 'PUT') {
        product.addAll(Map<String, dynamic>.from(request.data as Map));
      }
      data = product;
      if (request.method == 'DELETE') {
        products.remove(product);
        failProductList = failRefreshAfterDelete;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

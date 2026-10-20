import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/produk.dart';
import 'api_client.dart';

class ProdukApi {
  ProdukApi(this.client);
  final ApiClient client;

  Future<List<Produk>> list({String q = '', String kategori = ''}) async {
    final data = (await client.dio.get<List<dynamic>>(
      '/produk',
      queryParameters: {
        if (q.isNotEmpty) 'q': q,
        if (kategori.isNotEmpty) 'kategori': kategori,
      },
    )).data!;
    return data
        .map((item) => Produk.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Produk> detail(String id) async => Produk.fromJson(
    (await client.dio.get<Map<String, dynamic>>('/produk/$id')).data!,
  );

  Future<Produk> create(Map<String, dynamic> data) async => Produk.fromJson(
    (await client.dio.post<Map<String, dynamic>>('/produk', data: data)).data!,
  );

  Future<Produk> update(String id, Map<String, dynamic> data) async =>
      Produk.fromJson(
        (await client.dio.put<Map<String, dynamic>>(
          '/produk/$id',
          data: data,
        )).data!,
      );

  Future<void> delete(String id) async =>
      client.dio.delete<void>('/produk/$id');

  Future<Produk> toggle(String id) async => Produk.fromJson(
    (await client.dio.patch<Map<String, dynamic>>('/produk/$id/toggle')).data!,
  );

  Future<Produk> uploadFoto(String id, Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final mime = ext == 'jpg' || ext == 'jpeg' ? 'jpeg' : ext;
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('image', mime),
      ),
    });
    return Produk.fromJson(
      (await client.dio.post<Map<String, dynamic>>(
        '/produk/$id/foto',
        data: form,
      )).data!,
    );
  }
}

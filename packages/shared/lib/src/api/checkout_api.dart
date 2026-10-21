import 'package:dio/dio.dart';

import '../models/pembayaran.dart';
import 'api_client.dart';

class CheckoutApi {
  CheckoutApi(this.client);
  final ApiClient client;
  Future<Map<String, dynamic>> preview(Map<String, dynamic> data) async =>
      (await client.dio.post<Map<String, dynamic>>(
        '/checkout/preview',
        data: data,
      )).data!;
  Future<HasilCheckout> checkout(
    Map<String, dynamic> data, {
    required String requestKey,
  }) async => HasilCheckout.fromJson(
    (await client.dio.post<Map<String, dynamic>>(
      '/checkout',
      data: data,
      options: Options(headers: {'Idempotency-Key': requestKey}),
    )).data!,
  );
  Future<Pembayaran> cekStatusBayar(String id) async => Pembayaran.fromJson(
    (await client.dio.get<Map<String, dynamic>>('/pembayaran/$id/status'))
        .data!,
  );
}

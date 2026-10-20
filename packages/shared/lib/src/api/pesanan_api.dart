import '../models/pesanan.dart';
import 'api_client.dart';

class PesananApi {
  PesananApi(this.client);
  final ApiClient client;

  Future<List<Pesanan>> list({String? status}) async {
    final data = (await client.dio.get<List<dynamic>>(
      '/pesanan',
      queryParameters: {'status': ?status},
    )).data!;
    return data
        .map((item) => Pesanan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Pesanan> detail(String id) async => Pesanan.fromJson(
    (await client.dio.get<Map<String, dynamic>>('/pesanan/$id')).data!,
  );

  Future<Pesanan> _patch(
    String id,
    String action, [
    Map<String, dynamic>? data,
  ]) async => Pesanan.fromJson(
    (await client.dio.patch<Map<String, dynamic>>(
      '/pesanan/$id/$action',
      data: data,
    )).data!,
  );

  Future<Pesanan> terima(String id) => _patch(id, 'terima');
  Future<Pesanan> tolak(String id, String alasan) =>
      _patch(id, 'tolak', {'alasan': alasan});
  Future<Pesanan> updateStatus(String id, String status) =>
      _patch(id, 'status', {'status': status});
  Future<Pesanan> urungkan(String id) => _patch(id, 'urungkan');
}

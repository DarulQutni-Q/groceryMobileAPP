import '../models/pesanan.dart';
import '../models/riwayat.dart';
import 'api_client.dart';

class PesananApi {
  PesananApi(this.client);
  final ApiClient client;

  Future<List<Pesanan>> list({String? status}) async {
    final data = (await client.dio.get<dynamic>(
      '/pesanan',
      queryParameters: {'status': ?status},
    )).data;
    // Backend pelanggan selalu mengembalikan Page {"data": [...], "meta":
    // {...}}; klien lain (dan mock lama) memakai list mentah. Terima
    // keduanya supaya tidak gagal cast.
    final rows = data is List
        ? data
        : (data as Map<String, dynamic>)['data'] as List<dynamic>;
    return rows
        .map((item) => Pesanan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Jejak status satu pesanan (customer, pesanan sendiri).
  Future<List<RiwayatStatus>> riwayat(String id) async {
    final data = (await client.dio.get<List<dynamic>>('/pesanan/$id/riwayat'))
        .data!;
    return data
        .map((item) => RiwayatStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Pesanan> detail(String id) async {
    final data = (await client.dio.get<dynamic>('/pesanan/$id')).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }

  Future<Pesanan> terima(String id) async {
    final data = (await client.dio.patch<dynamic>('/pesanan/$id/terima')).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }

  Future<Pesanan> tolak(String id, String alasan) async {
    final data = (await client.dio.patch<dynamic>(
      '/pesanan/$id/tolak',
      data: {'alasan': alasan},
    )).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }

  Future<Pesanan> updateStatus(String id, String status) async {
    final data = (await client.dio.patch<dynamic>(
      '/pesanan/$id/status',
      data: {'status': status},
    )).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }

  Future<Pesanan> urungkan(String id) async {
    final data = (await client.dio.patch<dynamic>('/pesanan/$id/urungkan')).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }

  Future<Pesanan> batalkan(String id) async {
    final data = (await client.dio.patch<dynamic>('/pesanan/$id/batalkan')).data;
    return Pesanan.fromJson(data as Map<String, dynamic>);
  }
}

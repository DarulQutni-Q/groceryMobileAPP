import '../models/notifikasi.dart';
import 'api_client.dart';

class NotifikasiApi {
  NotifikasiApi(this.client);
  final ApiClient client;

  Future<NotifikasiList> list({int limit = 50, int offset = 0}) async {
    final data = (await client.dio.get<dynamic>(
      '/notifikasi',
      queryParameters: {'limit': limit, 'offset': offset},
    ))
        .data;
    return NotifikasiList.fromJson(data as Map<String, dynamic>);
  }

  Future<Notifikasi> tandaiBaca(String id) async {
    final data =
        (await client.dio.patch<dynamic>('/notifikasi/$id/baca')).data;
    return Notifikasi.fromJson(data as Map<String, dynamic>);
  }

  Future<int> tandaiSemuaBaca() async {
    final data =
        (await client.dio.patch<dynamic>('/notifikasi/baca-semua')).data;
    return (data as Map<String, dynamic>)['dibaca'] as int;
  }
}

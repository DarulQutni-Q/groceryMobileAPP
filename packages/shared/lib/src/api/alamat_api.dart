import '../models/alamat.dart';
import 'api_client.dart';

class AlamatApi {
  AlamatApi(this.client);
  final ApiClient client;
  Future<List<Alamat>> list() async =>
      (await client.dio.get<List<dynamic>>('/alamat')).data!
          .map((item) => Alamat.fromJson(item as Map<String, dynamic>))
          .toList();
  Future<Alamat> create(Map<String, dynamic> data) async => Alamat.fromJson(
    (await client.dio.post<Map<String, dynamic>>('/alamat', data: data)).data!,
  );
  Future<Alamat> update(String id, Map<String, dynamic> data) async =>
      Alamat.fromJson(
        (await client.dio.put<Map<String, dynamic>>(
          '/alamat/$id',
          data: data,
        )).data!,
      );
  Future<void> delete(String id) async =>
      client.dio.delete<void>('/alamat/$id');
  Future<Alamat> jadikanUtama(String id) async => Alamat.fromJson(
    (await client.dio.patch<Map<String, dynamic>>('/alamat/$id/jadikan-utama'))
        .data!,
  );
}

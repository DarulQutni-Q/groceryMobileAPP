import '../models/toko.dart';
import '../models/halaman.dart';
import 'api_client.dart';

class TokoApi {
  TokoApi(this.client);
  final ApiClient client;

  Future<Halaman<Toko>> list({int page = 1, int perPage = 20}) async =>
      Halaman.fromJson(
        (await client.dio.get<Map<String, dynamic>>(
          '/toko',
          queryParameters: {'page': page, 'per_page': perPage},
        )).data!,
        Toko.fromJson,
      );

  Future<Toko> detail(String id) async => Toko.fromJson(
    (await client.dio.get<Map<String, dynamic>>('/toko/$id')).data!,
  );

  Future<Toko> getProfil() async => Toko.fromJson(
    (await client.dio.get<Map<String, dynamic>>('/toko/me')).data!,
  );

  Future<Toko> updateProfil(Map<String, dynamic> data) async => Toko.fromJson(
    (await client.dio.put<Map<String, dynamic>>('/toko/me', data: data)).data!,
  );

  Future<Toko> updateStatus(String status) async => Toko.fromJson(
    (await client.dio.patch<Map<String, dynamic>>(
      '/toko/me/status',
      data: {'status': status},
    )).data!,
  );

  Future<List<JamBuka>> getJamBuka() async {
    final data = (await client.dio.get<List<dynamic>>('/toko/me/jam-buka'))
        .data!;
    return data
        .map((item) => JamBuka.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<JamBuka>> updateJamBuka(List<JamBuka> days) async {
    final data = (await client.dio.put<List<dynamic>>(
      '/toko/me/jam-buka',
      data: days.map((day) => day.toJson()).toList(),
    )).data!;
    return data
        .map((item) => JamBuka.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

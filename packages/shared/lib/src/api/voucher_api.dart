import '../models/voucher.dart';
import 'api_client.dart';

class VoucherApi {
  VoucherApi(this.client);
  final ApiClient client;

  /// Voucher aktif milik satu toko, untuk pemilih voucher customer.
  Future<List<Voucher>> listToko(String tokoId) async {
    final data = (await client.dio.get<dynamic>('/voucher/toko/$tokoId')).data;
    return (data as List<dynamic>)
        .map((item) => Voucher.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Semua voucher toko sendiri, untuk kelola voucher seller.
  Future<List<Voucher>> listMine() async {
    final data = (await client.dio.get<dynamic>('/voucher')).data;
    return (data as List<dynamic>)
        .map((item) => Voucher.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Voucher> create(Map<String, dynamic> data) async {
    final result = (await client.dio.post<dynamic>('/voucher', data: data)).data;
    return Voucher.fromJson(result as Map<String, dynamic>);
  }

  Future<Voucher> setAktif(String id, bool aktif) async {
    final result = (await client.dio.patch<dynamic>(
      '/voucher/$id',
      data: {'aktif': aktif},
    ))
        .data;
    return Voucher.fromJson(result as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await client.dio.delete<dynamic>('/voucher/$id');
  }
}

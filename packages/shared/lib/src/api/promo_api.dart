import '../models/promo.dart';
import 'api_client.dart';

class PromoApi {
  PromoApi(this.client);
  final ApiClient client;

  Future<List<Promo>> list() async =>
      (await client.dio.get<List<dynamic>>('/promo')).data!
          .map((item) => Promo.fromJson(item as Map<String, dynamic>))
          .toList();
}

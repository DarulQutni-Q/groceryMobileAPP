
import '../models/versi_minimum.dart';
import 'api_client.dart';

/// Klien endpoint /versi-minimum (publik, tanpa token).
class VersiApi {
  VersiApi(this.client);
  final ApiClient client;

  Future<CekVersi> cek(String aplikasi, String versi) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '/versi-minimum',
      queryParameters: {'aplikasi': aplikasi, 'versi': versi},
    );
    return CekVersi.fromJson(response.data!);
  }
}

/// Pengecekan sekali jalan yang dipakai gerbang versi di tiap aplikasi:
/// galat apa pun (offline, server mati) berarti fail-open, aplikasi jalan.
Future<bool> wajibUpdateDariServer(VersiApi api, String aplikasi, String versi) async {
  try {
    return (await api.cek(aplikasi, versi)).wajibUpdate;
  } catch (_) {
    return false;
  }
}

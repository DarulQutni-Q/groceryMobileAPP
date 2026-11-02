import '../models/chat.dart';
import 'api_client.dart';

/// Chat per pesanan. Sisi customer memakai jalur /chat/pesanan,
/// sisi toko memakai /chat/toko/pesanan (peran pengirim ditentukan server
/// dari pemanggil, bukan dari payload).
class ChatApi {
  ChatApi(this.client, {this.sisiToko = false});
  final ApiClient client;
  final bool sisiToko;

  String get _dasar => sisiToko ? '/chat/toko/pesanan' : '/chat/pesanan';

  Future<List<ChatPesan>> list(String pesananId) async {
    final data = (await client.dio.get<List<dynamic>>('$_dasar/$pesananId'))
        .data!;
    return data
        .map((item) => ChatPesan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatPesan> kirim(String pesananId, String isi) async {
    final data = (await client.dio.post<Map<String, dynamic>>(
      '$_dasar/$pesananId',
      data: {'isi': isi},
    )).data!;
    return ChatPesan.fromJson(data);
  }
}

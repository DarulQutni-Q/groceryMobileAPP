import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';

class Tokens {
  const Tokens(this.accessToken, this.refreshToken);
  final String accessToken;
  final String refreshToken;

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      Tokens(json['access_token'] as String, json['refresh_token'] as String);
}

class AuthApi {
  AuthApi(this.client);
  final ApiClient client;

  Future<Tokens> _session(String path, Map<String, dynamic> data) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': true}),
    );
    return Tokens.fromJson(response.data!);
  }

  Future<Tokens> registerSeller({
    required String namaPemilik,
    required String namaToko,
    required String email,
    required String password,
    String? phone,
  }) => _session('/auth/register', {
    'nama_pemilik': namaPemilik,
    'nama_toko': namaToko,
    'email': email,
    'password': password,
    'phone': ?phone,
  });

  Future<Tokens> login(String email, String password) =>
      _session('/auth/login', {'email': email, 'password': password});

  Future<Tokens> loginWithGoogle(String idToken) =>
      _session('/auth/google', {'id_token': idToken});

  Future<Tokens> refreshToken(String token) =>
      _session('/auth/refresh', {'refresh_token': token});

  Future<User> getMe() async {
    final response = await client.dio.get<Map<String, dynamic>>('/auth/me');
    return User.fromJson(response.data!);
  }

  Future<void> updateFcmToken(String token) async {
    await client.dio.patch<void>('/auth/fcm-token', data: {'fcm_token': token});
  }
}

String authErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.unknown &&
        (error.message?.startsWith('Sesi ') ?? false)) {
      return error.message!;
    }
    final data = error.response?.data;
    final detail = data is Map ? data['detail'] : null;
    if (detail is String) return detail;
    if (detail is List) {
      return detail
          .whereType<Map>()
          .map((item) => item['message'] ?? 'Isian tidak valid')
          .join('\n');
    }
    if (error.response?.statusCode == 401) {
      return 'Sesi berakhir. Silakan login kembali.';
    }
    return 'Belum dapat terhubung ke server. Periksa koneksi lalu coba lagi.';
  }
  return 'Proses belum berhasil. Silakan coba lagi.';
}

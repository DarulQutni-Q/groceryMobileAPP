import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Klien API admin dashboard.
///
/// Base URL default = origin halaman yang sedang dibuka, supaya build web
/// yang diserve backend di /dashboard langsung same-origin tanpa CORS.
/// Override pakai --dart-define API_BASE_URL=... bila diserve terpisah.
class AdminApi {
  AdminApi({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? _defaultBaseUrl(),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  static String _defaultBaseUrl() {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    final origin = Uri.base.origin;
    if (origin.startsWith('http')) return origin;
    return 'http://43.173.52.180:8001';
  }

  final Dio _dio;
  String? _token;

  String? get token => _token;

  Future<void> muatToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  Future<void> _simpanToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('admin_token');
    } else {
      await prefs.setString('admin_token', token);
    }
  }

  Options _opts() => Options(
        headers: _token == null
            ? null
            : {'Authorization': 'Bearer $_token'},
      );

  /// Mengembalikan pesan galat server yang paling menjelaskan, atau null.
  static String? pesanGalat(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      return 'Server menjawab ${error.response?.statusCode ?? 'tanpa status'}';
    }
    return error.toString();
  }

  Future<void> login(String email, String password) async {
    final resp = await _dio.post(
      '/auth/login',
      data: {'role': 'admin', 'email': email, 'password': password},
    );
    await _simpanToken(resp.data['access_token'] as String);
  }

  Future<void> logout() => _simpanToken(null);

  Future<Map<String, dynamic>> ringkasan() async {
    final resp = await _dio.get('/admin/ringkasan', options: _opts());
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> kesehatan() async {
    final resp = await _dio.get('/admin/kesehatan', options: _opts());
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> versiMinimum() async {
    final resp = await _dio.get('/admin/versi-minimum', options: _opts());
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> ubahVersiMinimum({
    String? customer,
    String? seller,
  }) async {
    final data = <String, String>{};
    if (customer != null) data['customer'] = customer;
    if (seller != null) data['seller'] = seller;
    final resp = await _dio.patch(
      '/admin/versi-minimum',
      data: data,
      options: _opts(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Daftar halaman: mengembalikan {'data': [...], 'meta': {...}}.
  Future<Map<String, dynamic>> daftar(
    String path, {
    int page = 1,
    int perPage = 20,
    Map<String, String>? filter,
  }) async {
    final resp = await _dio.get(
      path,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        ...?filter,
      },
      options: _opts(),
    );
    final data = resp.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {
      'data': data,
      'meta': {'page': 1, 'per_page': 20, 'total': (data as List).length,
        'total_pages': 1},
    };
  }

  Future<Map<String, dynamic>> ubahStatusToko(
    String tokoId,
    String status,
  ) async {
    final resp = await _dio.patch(
      '/admin/toko/$tokoId/status',
      data: {'status': status},
      options: _opts(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> hapusPengguna(String userId) async {
    await _dio.delete('/admin/pengguna/$userId', options: _opts());
  }
}

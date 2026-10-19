import 'package:dio/dio.dart';

import '../core/secure_storage.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.storage,
    Dio? dio,
    Dio? refreshDio,
    this.onSessionExpired,
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)),
       _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    final uri = Uri.parse(baseUrl);
    if (!uri.hasAuthority || !['http', 'https'].contains(uri.scheme)) {
      throw ArgumentError('Alamat API belum dikonfigurasi dengan benar');
    }
    this.dio.options.connectTimeout = const Duration(seconds: 15);
    this.dio.options.receiveTimeout = const Duration(seconds: 15);
    _refreshDio.options.connectTimeout = const Duration(seconds: 15);
    _refreshDio.options.receiveTimeout = const Duration(seconds: 15);
    this.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _authorize, onError: _handleUnauthorized),
    );
  }

  final Dio dio;
  final SecureStorage storage;
  final Dio _refreshDio;
  Future<String>? _refreshing;
  int? _refreshGeneration;
  void Function()? onSessionExpired;

  Future<void> _authorize(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.extra['skipAuth'] != true) {
        final generation = storage.generation;
        final original = options.extra['sessionGeneration'];
        final token = await storage.readAccessToken();
        if (generation != storage.generation ||
            (original != null && original != generation)) {
          throw StateError('Request berasal dari sesi lama');
        }
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.extra['sessionGeneration'] = generation;
      }
      handler.next(options);
    } catch (error, stack) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stack,
          message: 'Sesi belum dapat dibaca. Silakan coba lagi.',
        ),
      );
    }
  }

  Future<void> _handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['skipAuth'] == true ||
        request.extra['sessionGeneration'] != storage.generation) {
      return handler.next(error);
    }
    if (request.extra['retried'] == true) {
      return _rejectWithExpiry(error, handler);
    }
    try {
      final current = await storage.readAccessToken();
      final sent = request.headers['Authorization'];
      final token = current != null && sent != 'Bearer $current'
          ? current
          : await _refreshOnce(request.extra['sessionGeneration'] as int);
      final retry = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $token'},
        extra: {...request.extra, 'retried': true},
      );
      handler.resolve(await dio.fetch<dynamic>(retry));
    } catch (failure, stack) {
      await _rejectWithExpiry(
        failure is DioException
            ? failure
            : DioException(
                requestOptions: request,
                error: failure,
                stackTrace: stack,
                message: 'Sesi berakhir. Silakan login kembali.',
              ),
        handler,
        request: request,
      );
    }
  }

  Future<String> _refreshOnce(int generation) async {
    final pending = _refreshing;
    if (pending != null && _refreshGeneration == generation) return pending;
    final future = _refreshSession(generation);
    _refreshing = future;
    _refreshGeneration = generation;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Future<String> _refreshSession(int generation) async {
    final refresh = await storage.readRefreshToken();
    if (refresh == null) throw StateError('Sesi berakhir');
    final result = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );
    if (storage.generation != generation) {
      throw StateError('Sesi sudah berubah');
    }
    final access = result.data?['access_token'] as String?;
    final nextRefresh = result.data?['refresh_token'] as String?;
    if (access == null || nextRefresh == null) {
      throw StateError('Respons sesi tidak valid');
    }
    await storage.saveSession(access, nextRefresh, refreshed: true);
    return access;
  }

  Future<void> _expire(RequestOptions request) async {
    if (request.extra['sessionGeneration'] != storage.generation) return;
    final deletion = storage.clearSession();
    final generation = storage.generation;
    await deletion;
    if (storage.generation == generation) onSessionExpired?.call();
  }

  Future<void> _rejectWithExpiry(
    DioException error,
    ErrorInterceptorHandler handler, {
    RequestOptions? request,
  }) async {
    try {
      await _expire(request ?? error.requestOptions);
      handler.reject(error);
    } catch (failure, stack) {
      handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          error: failure,
          stackTrace: stack,
          message: 'Sesi belum dapat dihapus. Silakan coba lagi.',
        ),
      );
    }
  }
}

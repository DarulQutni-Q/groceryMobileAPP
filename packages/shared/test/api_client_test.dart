import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, int status) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> saved;
  late SecureStorage storage;
  var failWrite = false;
  var failDelete = false;
  Completer<void>? deletePause;
  Completer<void>? deleteStarted;

  setUp(() {
    saved = {};
    failWrite = false;
    failDelete = false;
    deletePause = null;
    deleteStarted = null;
    storage = SecureStorage();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String?;
            if (call.method == 'write') {
              if (failWrite) {
                throw PlatformException(code: 'keystore-unavailable');
              }
              saved[key!] = args['value'] as String;
            }
            if (call.method == 'delete') {
              deleteStarted?.complete();
              if (deletePause != null) await deletePause!.future;
              if (failDelete) {
                throw PlatformException(code: 'keystore-unavailable');
              }
              saved.remove(key);
            }
            if (call.method == 'read') return saved[key];
            return null;
          },
        );
  });

  test('401 refreshes once and replays the authenticated request', () async {
    await storage.saveSession('old-access', 'old-refresh');
    var refreshCount = 0;
    final transport = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    transport.httpClientAdapter = TestAdapter(
      (request) async => request.headers['Authorization'] == 'Bearer new-access'
          ? jsonBody({'nama': 'Pemilik'}, 200)
          : jsonBody({}, 401),
    );
    final refresh = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    refresh.httpClientAdapter = TestAdapter((request) async {
      refreshCount++;
      expect(request.path, '/auth/refresh');
      expect(request.data, {'refresh_token': 'old-refresh'});
      return jsonBody({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }, 200);
    });
    final api = ApiClient(
      baseUrl: transport.options.baseUrl,
      storage: storage,
      dio: transport,
      refreshDio: refresh,
    );
    final result = await api.dio.get<Map<String, dynamic>>('/auth/me');
    expect(result.statusCode, 200);
    expect(refreshCount, 1);
    expect(await storage.readAccessToken(), 'new-access');
    expect(await storage.readRefreshToken(), 'new-refresh');
  });

  test('concurrent unauthorized requests share one refresh', () async {
    await storage.saveSession('old-access', 'old-refresh');
    var refreshCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter(
      (request) async => request.headers['Authorization'] == 'Bearer renewed'
          ? jsonBody({}, 200)
          : jsonBody({}, 401),
    );
    final refresh = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    refresh.httpClientAdapter = TestAdapter((_) async {
      refreshCount++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return jsonBody({
        'access_token': 'renewed',
        'refresh_token': 'next-refresh',
      }, 200);
    });
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: storage,
      dio: dio,
      refreshDio: refresh,
    );
    final results = await Future.wait(
      List.generate(5, (_) => api.dio.get<dynamic>('/auth/me')),
    );
    expect(results.every((response) => response.statusCode == 200), isTrue);
    expect(refreshCount, 1);
  });

  test(
    'expired cleanup does not cancel a newer login during slow deletion',
    () async {
      await storage.saveSession('old-access', 'old-refresh');
      deletePause = Completer<void>();
      deleteStarted = Completer<void>();
      var expired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
      final refresh = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      refresh.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
      final api = ApiClient(
        baseUrl: dio.options.baseUrl,
        storage: storage,
        dio: dio,
        refreshDio: refresh,
        onSessionExpired: () => expired++,
      );
      final request = expectLater(
        api.dio.get<dynamic>('/auth/me'),
        throwsA(isA<DioException>()),
      );
      await deleteStarted!.future;
      final login = storage.saveSession(
        'new-account-access',
        'new-account-refresh',
      );
      deletePause!.complete();
      await Future.wait([request, login]);
      expect(expired, 0);
      expect(await storage.readAccessToken(), 'new-account-access');
    },
  );

  test('storage can retry after a failed write', () async {
    failWrite = true;
    await expectLater(
      storage.saveSession('access', 'refresh'),
      throwsA(isA<PlatformException>()),
    );
    failWrite = false;
    await storage.saveSession('next-access', 'next-refresh');
    expect(await storage.readAccessToken(), 'next-access');
  });

  test('an invalid refresh clears the session and calls logout once', () async {
    await storage.saveSession('old-access', 'old-refresh');
    var expired = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
    final refresh = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    refresh.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: storage,
      dio: dio,
      refreshDio: refresh,
      onSessionExpired: () => expired++,
    );
    await expectLater(
      api.dio.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(expired, 1);
  });

  test('failed secure deletion completes the request with an error', () async {
    await storage.saveSession('old-access', 'old-refresh');
    failDelete = true;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
    final refresh = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    refresh.httpClientAdapter = TestAdapter((_) async => jsonBody({}, 401));
    final api = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: storage,
      dio: dio,
      refreshDio: refresh,
    );
    await expectLater(
      api.dio.get<dynamic>('/auth/me').timeout(const Duration(seconds: 1)),
      throwsA(isA<DioException>()),
    );
  });

  test(
    'a request from the previous account is never replayed as the new account',
    () async {
      await storage.saveSession('account-a', 'refresh-a');
      final started = Completer<void>();
      final response = Completer<ResponseBody>();
      var newAccountRequests = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = TestAdapter((request) async {
        if (request.headers['Authorization'] == 'Bearer account-a') {
          started.complete();
          return response.future;
        }
        newAccountRequests++;
        return jsonBody({}, 200);
      });
      final api = ApiClient(
        baseUrl: dio.options.baseUrl,
        storage: storage,
        dio: dio,
      );
      final pending = api.dio.get<dynamic>('/auth/me');
      final assertion = expectLater(pending, throwsA(isA<DioException>()));
      await started.future;
      await storage.clearSession();
      await storage.saveSession('account-b', 'refresh-b');
      response.complete(jsonBody({}, 401));
      await assertion;
      expect(newAccountRequests, 0);
      expect(await storage.readAccessToken(), 'account-b');
    },
  );
}

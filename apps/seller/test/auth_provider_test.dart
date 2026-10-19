import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/features/auth/application/auth_provider.dart';

class AuthTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final isProfile = request.path == '/auth/me';
    final result = isProfile
        ? {
            'id': 'seller-id',
            'nama': 'Pemilik',
            'email': 'seller@example.com',
            'role': 'seller',
            'nama_toko': 'Toko Uji',
            'phone': null,
          }
        : {'access_token': 'access', 'refresh_token': 'refresh'};
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('login persists a session, restores it, and logout clears it', () async {
    final saved = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'write') saved[key] = args['value'] as String;
            if (call.method == 'delete') saved.remove(key);
            if (call.method == 'read') return saved[key];
            return null;
          },
        );
    final storage = SecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = AuthTransport();
    final api = AuthApi(
      ApiClient(baseUrl: dio.options.baseUrl, storage: storage, dio: dio),
    );
    final auth = AuthNotifier(api, storage);
    expect(await auth.login('seller@example.com', 'SandiUji123!'), isTrue);
    expect(auth.state.status, AuthStatus.authenticated);
    expect(auth.state.user?.namaToko, 'Toko Uji');
    final reopened = AuthNotifier(api, storage);
    await reopened.checkSession();
    expect(reopened.state.status, AuthStatus.authenticated);
    await reopened.logout();
    expect(await storage.readRefreshToken(), isNull);
    expect(reopened.state.status, AuthStatus.unauthenticated);
    auth.dispose();
    reopened.dispose();
  });
}

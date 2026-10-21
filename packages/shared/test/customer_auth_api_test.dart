import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthApi api;
  late SecureStorage storage;
  late List<RequestOptions> calls;
  late Map<String, String> saved;

  setUp(() {
    calls = [];
    saved = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'read') return saved[key];
            if (call.method == 'write') saved[key] = args['value'] as String;
            if (call.method == 'delete') saved.remove(key);
            return null;
          },
        );
    storage = SecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((options) async {
      calls.add(options);
      return jsonBody({
        'access_token': 'access',
        'refresh_token': 'refresh',
      }, 200);
    });
    api = AuthApi(
      ApiClient(baseUrl: dio.options.baseUrl, storage: storage, dio: dio),
    );
  });

  test(
    'customer registration reuses session endpoint with real email and phone',
    () async {
      final tokens = await api.registerCustomer(
        email: 'pembeli@example.com',
        phone: '081234567890',
        password: 'SandiCustomer123!',
      );
      expect(tokens.accessToken, 'access');
      expect(calls.single.path, '/auth/register');
      expect(calls.single.data, {
        'role': 'customer',
        'email': 'pembeli@example.com',
        'phone': '081234567890',
        'password': 'SandiCustomer123!',
      });
      expect(calls.single.extra['skipAuth'], isTrue);
      expect(calls.single.headers.containsKey('Authorization'), isFalse);
    },
  );

  test(
    'phone login uses phone endpoint without creating synthetic email',
    () async {
      await api.loginCustomer('081234567890', 'SandiCustomer123!');
      expect(calls.single.path, '/auth/login/phone');
      expect(calls.single.data, {
        'phone': '081234567890',
        'password': 'SandiCustomer123!',
      });
      await api.loginCustomer('pembeli@example.com', 'SandiCustomer123!');
      expect(calls.last.path, '/auth/login');
      expect((calls.last.data as Map)['role'], 'customer');
    },
  );

  test(
    'Google selects customer role while legacy seller payload stays unchanged',
    () async {
      await api.loginWithGoogle('google-id-token', role: 'customer');
      expect(calls.last.data, {
        'id_token': 'google-id-token',
        'role': 'customer',
      });
      await api.loginWithGoogle('google-id-token');
      expect(calls.last.data, {'id_token': 'google-id-token'});
    },
  );

  test(
    'remember preference does not remove or log encrypted session',
    () async {
      await storage.saveSession(
        'access-private-marker',
        'refresh-private-marker',
      );
      await storage.setRememberSession(false);
      expect(await storage.shouldRestoreSession(), isFalse);
      expect(
        jsonDecode(saved['auth_session']!)['refresh_token'],
        'refresh-private-marker',
      );
      await storage.setRememberSession(true);
      expect(await storage.shouldRestoreSession(), isTrue);
    },
  );
}

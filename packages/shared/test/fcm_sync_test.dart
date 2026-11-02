import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

import 'api_client_test.dart' show TestAdapter, jsonBody;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthApi api;
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
    final storage = SecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = TestAdapter((options) async {
      calls.add(options);
      return jsonBody({}, 200);
    });
    api = AuthApi(
      ApiClient(
        baseUrl: 'https://api.example.com',
        storage: storage,
        dio: dio,
      ),
    );
  });

  Future<void> waitForCalls(int n) async {
    for (var i = 0; i < 50 && calls.length < n; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('FID awal + FID baru ikut dikirim', () async {
    final controller = StreamController<String>();
    final done = syncFcmToken(
      api: api,
      register: () async {},
      registeredTokens: controller.stream,
    );
    controller.add('fid-awal');
    await waitForCalls(1);
    expect(calls.first.path, '/auth/fcm-token');
    expect(calls.first.data['fcm_token'], 'fid-awal');
    controller.add('fid-baru');
    await waitForCalls(2);
    expect(calls.last.data['fcm_token'], 'fid-baru');
    await controller.close();
    await done;
  });

  test('register gagal: tidak ada request, tidak throw', () async {
    // Stream tidak pernah di-listen karena register sudah throw duluan,
    // jadi pakai stream kosong (close pada controller tanpa listener
    // menggantung future-nya).
    await syncFcmToken(
      api: api,
      register: () async => throw StateError('no firebase'),
      registeredTokens: const Stream<String>.empty(),
    );
    expect(calls, isEmpty);
  });
}

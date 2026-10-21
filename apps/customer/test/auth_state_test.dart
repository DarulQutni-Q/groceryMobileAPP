import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';

class CustomerAdapter implements HttpClientAdapter {
  CustomerAdapter(this.respond);
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

ResponseBody response(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class AuthFixture {
  AuthFixture({this.role = 'customer'}) {
    storage = SecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = CustomerAdapter((request) async {
      calls.add(request);
      if (request.path == '/auth/me') {
        if (profileError) {
          return response({'detail': 'Server belum tersedia'}, 503);
        }
        return response({
          'id': 'customer-id',
          'nama': 'Pembeli',
          'email': 'pembeli@example.com',
          'role': role,
          'phone': '+6281234567890',
          'nama_toko': null,
        });
      }
      if (paused != null) await paused!.future;
      return response({'access_token': 'access', 'refresh_token': 'refresh'});
    });
    api = AuthApi(
      ApiClient(baseUrl: dio.options.baseUrl, storage: storage, dio: dio),
    );
  }
  final String role;
  late final AuthApi api;
  late final SecureStorage storage;
  final saved = <String, String>{};
  final calls = <RequestOptions>[];
  bool profileError = false;
  Completer<void>? paused;

  void installStorage() {
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
  }

  AuthNotifier notifier() =>
      AuthNotifier(api, storage, googleToken: () async => 'google-token');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthFixture fixture;
  setUp(() {
    fixture = AuthFixture()..installStorage();
  });

  test(
    'customer login persists and restores session then logout clears it',
    () async {
      final auth = fixture.notifier();
      expect(await auth.login('081234567890', 'SandiCustomer123!'), isTrue);
      expect(auth.state.status, AuthStatus.authenticated);
      expect(auth.state.user!.role, 'customer');
      final restored = fixture.notifier();
      await restored.checkSession();
      expect(restored.state.status, AuthStatus.authenticated);
      await restored.logout();
      expect(restored.state.status, AuthStatus.unauthenticated);
      expect(await fixture.storage.readRefreshToken(), isNull);
      auth.dispose();
      restored.dispose();
    },
  );

  test('unchecked remember me keeps current login but does not restore next launch', () async {
    final auth = fixture.notifier();
    expect(
      await auth.login('081234567890', 'SandiCustomer123!', remember: false),
      isTrue,
    );
    final restored = fixture.notifier();
    await restored.checkSession();
    expect(restored.state.status, AuthStatus.unauthenticated);
    expect(await fixture.storage.readAccessToken(), isNull);
    auth.dispose();
    restored.dispose();
  });

  test('late login cannot recreate session after logout', () async {
    fixture.paused = Completer<void>();
    final auth = fixture.notifier();
    final pending = auth.login('081234567890', 'SandiCustomer123!');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await auth.logout();
    fixture.paused!.complete();
    expect(await pending, isFalse);
    expect(auth.state.status, AuthStatus.unauthenticated);
    expect(await fixture.storage.readAccessToken(), isNull);
    auth.dispose();
  });

  test('temporary profile failure keeps tokens for retry and wrong role is refused', () async {
    await fixture.storage.saveSession('access', 'refresh');
    fixture.profileError = true;
    final auth = fixture.notifier();
    await auth.checkSession();
    expect(auth.state.status, AuthStatus.error);
    expect(await fixture.storage.readRefreshToken(), 'refresh');
    fixture.profileError = false;
    await auth.checkSession();
    expect(auth.state.status, AuthStatus.authenticated);
    auth.dispose();
    fixture = AuthFixture(role: 'seller')..installStorage();
    final wrongRole = fixture.notifier();
    expect(await wrongRole.login('081234567890', 'SandiCustomer123!'), isFalse);
    expect(wrongRole.state.status, AuthStatus.error);
    expect(await fixture.storage.readAccessToken(), isNull);
    wrongRole.dispose();
  });
}

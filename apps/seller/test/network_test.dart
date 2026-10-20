import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/core/network.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test(
    'offline preflight blocks login and save before transport, then recovers',
    () async {
      var connected = false;
      var sent = 0;
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.example.com',
          extra: {'skipAuth': true},
        ),
      );
      final client = ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: SecureStorage(),
      );
      configureSellerNetwork(client, () async => connected);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            sent++;
            handler.resolve(
              Response(requestOptions: request, data: <String, dynamic>{}),
            );
          },
        ),
      );
      for (final path in ['/auth/login', '/produk']) {
        await expectLater(
          dio.post<void>(path),
          throwsA(
            isA<DioException>().having(
              (error) => error.message,
              'pesan',
              'Tidak ada koneksi internet',
            ),
          ),
        );
      }
      expect(sent, 0);
      connected = true;
      await dio.get<void>('/toko/me');
      expect(sent, 1);
      dio.close();
    },
  );

  test(
    'a request waiting for connectivity cannot cross an account change',
    () async {
      final waiting = Completer<void>();
      final connection = Completer<bool>();
      var sent = 0;
      final storage = SecureStorage();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.example.com',
          extra: {'skipAuth': true},
        ),
      );
      final client = ApiClient(
        baseUrl: dio.options.baseUrl,
        dio: dio,
        storage: storage,
      );
      configureSellerNetwork(client, () {
        waiting.complete();
        return connection.future;
      });
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            sent++;
            handler.resolve(
              Response(requestOptions: request, data: <String, dynamic>{}),
            );
          },
        ),
      );
      final request = dio.post<void>('/produk');
      await waiting.future;
      await storage.clearSession();
      connection.complete(true);
      await expectLater(
        request,
        throwsA(
          isA<DioException>().having(
            (error) => error.message,
            'pesan',
            'Sesi sudah berubah. Silakan coba lagi.',
          ),
        ),
      );
      expect(sent, 0);
      dio.close();
    },
  );
}

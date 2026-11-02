import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:seller/features/store/application/store_provider.dart';
import 'package:seller/features/store/presentation/toko_editor.dart';

// PNG 1x1 transparan untuk tile peta di tes (tile nyata tidak dimuat).
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _MockResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _png.length;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_png).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _MockRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockResponse();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockRequest();
  @override
  void close({bool force = false}) {}
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
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

ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {Headers.contentTypeHeader: ['application/json']},
);

Map<String, dynamic> _tokoJson({double? lat, double? lon}) => {
  'id': 'toko-1',
  'owner_id': 'user-1',
  'nama': 'Toko Uji',
  'logo_url': null,
  'alamat': 'Jalan Melati 1',
  'telepon': '081234567890',
  'deskripsi': null,
  'kategori': [],
  'radius_km': 5,
  'status': 'buka',
  'metode_kirim': [],
  'rekening_bank': null,
  'latitude': lat,
  'longitude': lon,
  'created_at': '2026-11-02T00:00:00Z',
  'updated_at': '2026-11-02T00:00:00Z',
};

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  testWidgets('editor menampilkan peta dan simpan mengirim koordinat', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = _Adapter((request) async {
      if (request.path == '/toko/me' && request.method == 'GET') {
        return _json(_tokoJson(lat: 5.2443, lon: 97.0248));
      }
      if (request.path == '/toko/me' && request.method == 'PUT') {
        saved = Map<String, dynamic>.from(request.data as Map);
        return _json(_tokoJson(lat: 5.2443, lon: 97.0248));
      }
      return _json({'detail': 'Tidak ditemukan'}, 404);
    });
    final client = ApiClient(
      baseUrl: dio.options.baseUrl,
      storage: SecureStorage(),
      dio: dio,
    );
    client.dio.options.connectTimeout = null;
    client.dio.options.receiveTimeout = null;

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokoApiProvider.overrideWith((ref) => TokoApi(client)),
            produkApiProvider.overrideWith((ref) => ProdukApi(client)),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: TokoEditor(
                userId: 'user-1',
                toko: Toko.fromJson(_tokoJson(lat: 5.2443, lon: 97.0248)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('peta-toko')), findsOneWidget);
      expect(
        find.text('Titik: 5.24430, 97.02480'),
        findsOneWidget,
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!['latitude'], 5.2443);
      expect(saved!['longitude'], 97.0248);
    }, createHttpClient: (_) => _MockHttpClient());
    await tester.pumpAndSettle();
  });
}

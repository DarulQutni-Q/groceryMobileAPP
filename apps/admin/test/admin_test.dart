import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_admin/api.dart';
import 'package:gardenmart_admin/main.dart';
import 'package:gardenmart_admin/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );

AdminApi _apiDenganStub() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    if (request.path == '/auth/login') {
      if (request.data['password'] == 'benar') {
        return _json({'access_token': 'token-admin'});
      }
      return _json({'detail': 'Email atau kata sandi salah'}, 401);
    }
    if (request.path == '/admin/ringkasan') {
      return _json({
        'pengguna_total': 3,
        'pengguna_per_role': {'admin': 1, 'seller': 1, 'customer': 1},
        'toko_total': 1,
        'toko_buka': 1,
        'pesanan_total': 5,
        'pesanan_per_status': {'baru': 2, 'selesai': 3},
        'pesanan_hari_ini': 1,
        'omzet_selesai_7h': 100000,
        'omzet_selesai_30h': 250000,
        'baru_lewat_70_menit': 0,
        'token_fcm_total': 0,
      });
    }
    return _json({'detail': 'Tidak ditemukan'}, 404);
  });
  return AdminApi(dio: dio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rupiah memakai pemisah titik', () {
    expect(rupiah(67600), 'Rp 67.600');
    expect(rupiah(1000000), 'Rp 1.000.000');
    expect(rupiah(0), 'Rp 0');
  });

  test('login menyimpan token dan ringkasan terbaca', () async {
    final api = _apiDenganStub();
    await api.login('admin@example.com', 'benar');
    expect(api.token, 'token-admin');
    final data = await api.ringkasan();
    expect(data['pengguna_total'], 3);
    expect(data['omzet_selesai_7h'], 100000);
  });

  test('login gagal memberi pesan server', () async {
    final api = _apiDenganStub();
    try {
      await api.login('admin@example.com', 'salah');
      fail('seharusnya melempar');
    } catch (error) {
      expect(AdminApi.pesanGalat(error), 'Email atau kata sandi salah');
    }
  });

  testWidgets('login menolak email tidak valid tanpa request', (tester) async {
    final api = _apiDenganStub();
    var masuk = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(api: api, onMasuk: () => masuk = true),
      ),
    );
    await tester.enterText(find.byKey(const Key('login-email')), 'bukan-email');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'apapun',
    );
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Email tidak valid'), findsOneWidget);
    expect(masuk, isFalse);
  });
}

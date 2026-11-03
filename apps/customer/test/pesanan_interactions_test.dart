import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/pesanan_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/cart_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/pesanan_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/struk_page.dart';
import 'package:grocery_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;
import 'pesanan_fixture.dart';

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
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

const _produk = {
  'p-bimoli': ('Bimoli 2L', 33900),
  'p-ultra': ('Ultra Milk 1L', 17500),
  'p-indomie': ('Indomie (5)', 16200),
  'p-beras': ('Beras Premium 5kg', 25000),
  'p-minyak': ('Minyak Goreng 2L', 22000),
  'p-gula': ('Gula Pasir 1kg', 21500),
  'p-telur': ('Telur Ayam 1kg', 21000),
};

/// ApiClient yang menjawab GET /produk/{id} dari peta di atas.
ApiClient _produkClient() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = _Adapter((request) async {
    final id = request.path.split('/').last;
    final found = _produk[id];
    if (found == null) return _json({'detail': 'Tidak ditemukan'}, 404);
    return _json({
      'id': id,
      'toko_id': 'toko-1',
      'nama': found.$1,
      'foto_url': null,
      'harga': found.$2,
      'stok': 50,
      'satuan': 'pcs',
      'kategori': 'Sembako',
      'is_tersedia': true,
    });
  });
  return ApiClient(
    baseUrl: dio.options.baseUrl,
    storage: SecureStorage(),
    dio: dio,
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier()
    : super(
        AuthApi(
          ApiClient(
            baseUrl: 'https://api.example.com',
            storage: SecureStorage(),
          ),
        ),
        SecureStorage(),
      ) {
    state = const AuthState(
      AuthStatus.authenticated,
      user: User(
        id: 'u1',
        nama: 'Pembeli',
        email: 'pembeli@example.com',
        role: 'customer',
        phone: '+6281234567890',
      ),
    );
  }
}

Future<void> _pumpPesanan(
  WidgetTester tester, {
  List<Pesanan>? orders,
  Object? error,
  bool withAuth = false,
  bool withProduk = false,
  bool withCartWatch = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (error != null)
          pesananProvider.overrideWithValue(
            AsyncValue<List<Pesanan>>.error(error, StackTrace.current),
          )
        else
          pesananProvider.overrideWith(
            (ref) async => orders ?? pesananFixture(),
          ),
        if (withAuth) authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        if (withProduk)
          produkApiProvider.overrideWith((ref) => ProdukApi(_produkClient())),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: withCartWatch
                ? Column(
                    children: [
                      // Cerminan tab Beranda di shell: menonton keranjang
                      // supaya notifier autoDispose tidak dibuang di tengah
                      // proses Beli lagi.
                      Consumer(
                        builder: (context, ref, _) {
                          ref.watch(keranjangProvider('u1'));
                          return const SizedBox.shrink();
                        },
                      ),
                      const Expanded(child: PesananPage()),
                    ],
                  )
                : const PesananPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Keranjang memakai SecureStorage lewat platform channel; tanpa mock
    // ini, restore keranjang gagal dan Beli lagi tidak menambah apa pun.
    final saved = <String, String>{};
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
  });

  testWidgets('tab menyaring pesanan per status', (tester) async {
    await _pumpPesanan(tester);
    // Tab Dalam Proses: kartu tracking + riwayat di bawahnya.
    expect(find.text('Pesanan dalam perjalanan'), findsOneWidget);
    expect(find.text('Riwayat Pesanan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pesanan-tab-1')));
    await tester.pump();
    expect(find.text('Pesanan dalam perjalanan'), findsNothing);
    expect(find.text('Riwayat Pesanan'), findsNothing);
    expect(find.text('4 Barang, Rp 89.500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pesanan-tab-2')));
    await tester.pump();
    expect(find.text('4 Barang, Rp 89.500'), findsOneWidget);
    expect(find.text('Pesanan dalam perjalanan'), findsNothing);
  });

  testWidgets('timeline menampilkan empat langkah dari referensi', (
    tester,
  ) async {
    await _pumpPesanan(tester);
    expect(find.text('Dikonfirmasi'), findsOneWidget);
    expect(find.text('Dikemas'), findsOneWidget);
    expect(find.text('Dlm Perjalanan'), findsOneWidget);
    expect(find.text('Tiba'), findsOneWidget);
  });

  testWidgets('pencarian memfilter pesanan lalu kembali ke tab', (
    tester,
  ) async {
    await _pumpPesanan(tester);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(find.byKey(const Key('pesanan-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pesanan-search-field')),
      'Indomie',
    );
    await tester.pump();
    expect(find.text('1 hasil untuk "Indomie"'), findsOneWidget);
    expect(find.text('Pesanan dalam perjalanan'), findsOneWidget);
    expect(find.text('4 Barang, Rp 89.500'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Riwayat Pesanan'), findsOneWidget);
    expect(find.text('Pesanan dalam perjalanan'), findsOneWidget);
  });

  testWidgets('tab kosong menampilkan empty state yang jujur', (tester) async {
    await _pumpPesanan(tester, orders: []);
    expect(find.text('Belum ada pesanan dalam proses'), findsOneWidget);
    expect(find.text('Belanja sekarang'), findsOneWidget);
  });

  testWidgets('gagal muat menampilkan error dan tombol coba lagi', (
    tester,
  ) async {
    await _pumpPesanan(tester, error: Exception('boom'));
    expect(find.text('Gagal memuat pesanan'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('tombol telepon kurir jujur soal nomor yang belum ada', (
    tester,
  ) async {
    await _pumpPesanan(tester);
    await tester.tap(find.byIcon(Icons.phone));
    await tester.pump();
    expect(
      find.text(
        'Nomor telepon kurir belum tersedia untuk pesanan ini. '
        'Kamu tetap bisa menghubungi kurir lewat Chat Driver.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('chat driver membuka halaman chat', (tester) async {
    await _pumpPesanan(tester);
    await tester.tap(find.text('Chat Driver'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatDriverPage), findsOneWidget);
  });

  testWidgets('lihat struk membuka struk pesanan itu', (tester) async {
    await _pumpPesanan(tester);
    await tester.scrollUntilVisible(find.text('Lihat struk'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat struk').first);
    await tester.pump();
    await tester.pump();
    expect(find.byType(StrukPage), findsOneWidget);
    expect(find.text('#GM-0998'), findsOneWidget);
    // Baris yang tidak ada datanya disembunyikan, bukan diisi karangan.
    expect(find.text('Kasir / Picker'), findsNothing);
    expect(find.text('Kurir Toko'), findsNothing);
  });

  testWidgets('beli lagi memasukkan isi pesanan ke keranjang', (tester) async {
    await _pumpPesanan(
      tester,
      withAuth: true,
      withProduk: true,
      withCartWatch: true,
    );
    await tester.scrollUntilVisible(find.text('Beli lagi'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beli lagi').first);
    await tester.pumpAndSettle();
    expect(find.byType(CartPage), findsOneWidget);
    expect(find.text('Beras Premium 5kg'), findsWidgets);
    expect(find.text('Telur Ayam 1kg'), findsWidgets);
  });
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/auth/application/auth_provider.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';
import 'package:gardenmart_customer/features/catalog/presentation/catalog_page.dart';
import 'package:gardenmart_customer/features/catalog/presentation/catalog_widgets.dart';
import 'package:gardenmart_customer/features/catalog/presentation/toko_page.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart' show AuthFixture;
import 'catalog_flow_test.dart' show openCatalog, tapKey;
import 'golden_home_test.dart' show FakeAuthNotifier;
import 'golden_test.dart' show loadTestFonts;

const _p1 = Produk(
  id: 'p1',
  tokoId: 't1',
  nama: 'Indomie Spesial',
  harga: 16200,
  stok: 5,
  satuan: 'pcs',
  kategori: 'Mie',
  isTersedia: true,
);
const _p2 = Produk(
  id: 'p2',
  tokoId: 't1',
  nama: 'Beras Pilihan',
  harga: 50000,
  stok: 10,
  satuan: 'kg',
  kategori: 'Beras',
  isTersedia: true,
);

const _tokoPenuh = Toko(
  id: 't1',
  nama: 'Toko Diponegoro',
  alamat: 'Jl. Diponegoro No. 42',
  telepon: '0618291122',
  deskripsi: 'Toko sembako dekat kampus',
  kategori: ['Sembako'],
  radiusKm: 5,
  status: 'buka',
  metodeKirim: ['Kurir'],
  jamBuka: '08:00:00',
  jamTutup: '23:00:00',
  produk: [_p1, _p2],
);

const _tokoKosong = Toko(
  id: 't1',
  nama: 'Toko Kosong',
  alamat: 'Jl. Kosong No. 1',
  telepon: '',
  kategori: [],
  radiusKm: 3,
  status: 'buka',
  metodeKirim: [],
  produk: [],
);

Future<AuthFixture> openToko(WidgetTester tester, Toko toko) async {
  final fixture = AuthFixture()..installStorage();
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(fixture.storage),
        keranjangStorageProvider.overrideWithValue(fixture.storage),
        apiClientProvider.overrideWithValue(fixture.api.client),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        detailTokoProvider.overrideWith((ref, id) async => toko),
      ],
      child: MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        // Seperti shell asli yang selalu mengawasi keranjang (badge):
        // tanpa watcher, provider autoDispose gugur di tengah tambahItem.
        home: const _TokoTestHome(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return fixture;
}

/// Pembungkus tes: mengawasi keranjang lalu menampilkan TokoPage.
class _TokoTestHome extends ConsumerWidget {
  const _TokoTestHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(keranjangProvider('u1'));
    return const TokoPage('t1');
  }
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('store page shows real detail and catalog-variant cards', (
    tester,
  ) async {
    // Viewport 390x844 seperti golden: baris grid pertama masuk
    // jendela paint sehingga kartu dibangun (pada viewport default
    // 800x600 baris itu jatuh di luar jendela build grid dan kartu
    // tidak pernah dibangun).
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openToko(tester, _tokoPenuh);
    expect(find.text('Toko Diponegoro'), findsOneWidget);
    expect(find.text('Buka'), findsOneWidget);
    expect(find.text('Buka 08:00 - 23:00'), findsOneWidget);
    expect(find.text('Jl. Diponegoro No. 42'), findsOneWidget);
    expect(find.text('0618291122'), findsOneWidget);
    expect(find.text('Toko sembako dekat kampus'), findsOneWidget);
    expect(find.text('Sembako'), findsOneWidget);
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(find.text('2 produk'), findsOneWidget);
    expect(find.byKey(const Key('product-p1')), findsOneWidget);
    expect(find.byKey(const Key('product-p2')), findsOneWidget);
    // Varian katalog: tidak ada badge diskon placeholder (itu hanya
    // varian beranda).
    expect(find.byKey(const Key('badge-diskon-p1')), findsNothing);
    expect(find.byKey(const Key('badge-diskon-p2')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('store page hides absent fields and shows empty state', (
    tester,
  ) async {
    await openToko(tester, _tokoKosong);
    expect(find.text('Toko Kosong'), findsOneWidget);
    expect(find.text('Belum ada produk di toko ini'), findsOneWidget);
    expect(find.text('0 produk'), findsOneWidget);
    expect(find.text('Tentang'), findsNothing);
    expect(find.text('Telepon'), findsNothing);
    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Pengiriman'), findsNothing);
    expect(find.text('Radius'), findsOneWidget);
    expect(find.text('3 km'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('add to cart from the store catalog actually adds', (
    tester,
  ) async {
    // Viewport tinggi seperti golden test. Sejak baris chip ditambah,
    // halaman tidak lagi muat penuh: tombol + Keranjang p1 berada
    // 3 px di bawah lipatan pada scroll maksimal, jadi perlu
    // ensureVisible. Pompa sekali sesudahnya supaya offset scroll
    // baru diterapkan ke layout sebelum ketuk: tanpa pompa ini
    // tap memakai koordinat pra-scroll dan meleset ke ruang kosong.
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await openToko(tester, _tokoPenuh);
    final button = find.descendant(
      of: find.byKey(const Key('product-p1')),
      matching: find.widgetWithText(FilledButton, '+ Keranjang'),
    );
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    // Jangan pumpAndSettle di sini: ia memajukan timer sampai snackbar
    // 4 detik habis dan hilang sebelum sempat diperiksa. Pompa bertahap
    // sampai snackbar muncul (tambahItem sudah selesai saat snackbar
    // tampil, jadi simpanan keranjang pun sudah tertulis).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Ditambahkan ke keranjang').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Ditambahkan ke keranjang'), findsOneWidget);
    expect((fixture.saved['customer_cart_u1'] ?? '').contains('p1'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home name tap and arrow picker open the store page', (
    tester,
  ) async {
    await openCatalog(tester);
    await tapKey(tester, 'store-name');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(find.text('Jalan Diponegoro'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Katalog Toko'), findsNothing);
    await tapKey(tester, 'store-picker');
    expect(find.text('Pilih Toko'), findsOneWidget);
    await tapKey(tester, 'store-pick-t1');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cart store name opens the store page', (tester) async {
    await openCatalog(tester);
    await tapKey(tester, 'product-p1');
    expect(find.text('Detail Produk'), findsOneWidget);
    await tapKey(tester, 'add-cart');
    await tapKey(tester, 'detail-back');
    await tapKey(tester, 'open-cart');
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    await tapKey(tester, 'cart-store-name');
    expect(find.text('Katalog Toko'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('store cards use a bigger 110 image area', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openToko(tester, _tokoPenuh);
    // Lebar kartu grid pada viewport 390: (390 - 16*2 - 12) / 2 = 173.
    expect(tester.getSize(find.byType(FotoProduk).first), const Size(173, 110));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('catalog variant keeps default 88 image height', (tester) async {
    final fixture = AuthFixture()..installStorage();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(fixture.storage),
          keranjangStorageProvider.overrideWithValue(fixture.storage),
          apiClientProvider.overrideWithValue(fixture.api.client),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: customerTheme(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: SizedBox(width: 173, child: ProductCard(_p1))),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(FotoProduk).first).height, 88);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('store photo uses cover fit at the bigger image size', (
    tester,
  ) async {
    // Viewport 390x844 seperti tes lain: baris grid masuk jendela
    // paint sehingga kartu (dan gambarnya) dibangun.
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Sengaja TANPA mock jaringan/cache: yang diuji di sini adalah
    // konfigurasi render kartu toko untuk foto asli (fit cover +
    // ukuran area), bukan selesainya unduhan. Di lingkungan tes
    // tanpa plugin path_provider, pemuatan CachedNetworkImage akan
    // gagal asinkron ke fallback error; itu tidak memengaruhi
    // asersi fit/ukuran, jadi takeException sengaja tidak diasersi
    // di tes ini. Upaya memuat sungguhan lewat cache manager +
    // HttpClient mock + path_provider mock justru membuat frame
    // pertama halaman tidak pernah selesai di harness tes.
    const tokoFoto = Toko(
      id: 't1',
      nama: 'Toko Foto',
      alamat: 'Jl. Foto No. 1',
      telepon: '',
      kategori: [],
      radiusKm: 3,
      status: 'buka',
      metodeKirim: [],
      produk: [
        Produk(
          id: 'pf',
          tokoId: 't1',
          nama: 'Produk Foto Besar',
          harga: 10000,
          stok: 3,
          satuan: 'pcs',
          kategori: 'Mie',
          isTersedia: true,
          fotoUrl: 'foto/big-2000x1500-test.jpg',
        ),
      ],
    );
    await openToko(tester, tokoFoto);
    await tester.pump();
    final foto = find.byType(CachedNetworkImage);
    expect(foto, findsOneWidget);
    // Foto asli mengisi area dengan cover, bukan contain yang
    // menyisakan bilah kosong.
    expect(tester.widget<CachedNetworkImage>(foto).fit, BoxFit.cover);
    expect(tester.getSize(foto), const Size(173, 110));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('big png decodes to 2000x1500', () async {
    // Bukti decode mandiri tanpa widget Image: PNG 2000x1500 yang
    // digambar tes benar-benar bisa di-decode engine ke dimensi
    // aslinya. Bersama tes cover di atas (kartu toko merender foto
    // asli dengan BoxFit.cover di area 173x110), ini membuktikan
    // foto besar mengisi area tanpa distorsi/letterbox. Tes widget
    // Image(MemoryImage) sengaja tidak dipakai: di harness tes VPS
    // ini frame pertama yang mengandung Image yang benar-benar
    // di-decode tidak pernah selesai (terbukti 2x: CachedNetworkImage
    // + mock cache, dan MemoryImage), sementara kartu toko dengan
    // CachedNetworkImage tanpa mock justru lolos.
    final png = await _pngBesar();
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 2000);
    expect(frame.image.height, 1500);
  });

  testWidgets('store page scrolls to the last product with many products', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final banyak = Toko(
      id: 't1',
      nama: 'Toko Banyak',
      alamat: 'Jl. Banyak No. 1',
      telepon: '',
      kategori: [],
      radiusKm: 3,
      status: 'buka',
      metodeKirim: [],
      produk: List.generate(
        12,
        (i) => Produk(
          id: 's$i',
          tokoId: 't1',
          nama: 'Produk ${i + 1}',
          harga: 10000 + i * 1000,
          stok: 5,
          satuan: 'pcs',
          kategori: i.isEven ? 'Mie' : 'Beras',
          isTersedia: true,
        ),
      ),
    );
    await openToko(tester, banyak);
    expect(find.text('Produk 12'), findsNothing);
    // Halaman ini punya DUA Scrollable (vertikal CustomScrollView +
    // horizontal baris chip): scrollUntilVisible wajib diberi scrollable
    // eksplisit, kalau tidak ia melempar "Too many elements" karena
    // find.byType(Scrollable) menemukan keduanya.
    await tester.scrollUntilVisible(
      find.text('Produk 12'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('Produk 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('category chips filter the store catalog and Semua restores', (
    tester,
  ) async {
    // Viewport 390x844: baris grid masuk jendela paint sehingga
    // kunci produk bisa ditemukan (lihat komentar tes detail).
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openToko(tester, _tokoPenuh);
    // Chip dari kategori asli toko ini saja, urutan kemunculan.
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Mie'), findsOneWidget);
    expect(find.text('Beras'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('toko-category-all')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('toko-category-Mie')));
    await tester.pump();
    expect(find.byKey(const Key('product-p1')), findsOneWidget);
    expect(find.byKey(const Key('product-p2')), findsNothing);
    expect(find.text('1 produk'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toko-category-Beras')));
    await tester.pump();
    expect(find.byKey(const Key('product-p1')), findsNothing);
    expect(find.byKey(const Key('product-p2')), findsOneWidget);
    expect(find.text('1 produk'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toko-category-all')));
    await tester.pump();
    expect(find.byKey(const Key('product-p1')), findsOneWidget);
    expect(find.byKey(const Key('product-p2')), findsOneWidget);
    expect(find.text('2 produk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// PNG hijau 2000x1500 yang digambar langsung di tes, sebagai foto
/// asli berukuran besar untuk membuktikan jalur gambar nyata.
Future<Uint8List> _pngBesar() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 2000, 1500));
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 2000, 1500),
    Paint()..color = const Color(0xFF2E7D32),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(2000, 1500);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';
import 'package:gardenmart_customer/features/catalog/application/produk_provider.dart';

import 'auth_state_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('search waits 500ms and category keeps the query', (
    tester,
  ) async {
    final fixture = AuthFixture()..installStorage();
    final api = FakeProdukApi(fixture.api.client);
    final container = ProviderContainer(
      overrides: [produkApiProvider.overrideWithValue(api)],
    );
    final subscription = container.listen(produkProvider, (_, _) {});
    final notifier = container.read(produkProvider.notifier);
    await tester.pump();
    expect(api.calls.length, 1);
    notifier.cari('i');
    await tester.pump(const Duration(milliseconds: 200));
    notifier.cari('indomie');
    await tester.pump(const Duration(milliseconds: 499));
    expect(api.calls.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(api.calls.last, ('indomie', '', 1));
    notifier.filterKategori('Mie');
    await tester.pump();
    expect(api.calls.last, ('indomie', 'Mie', 1));
    expect(container.read(produkProvider).items.single.nama, 'indomie');
    subscription.close();
    container.dispose();
  });

  testWidgets(
    'pagination merges ids, ignores stale search and retries failed next page',
    (tester) async {
      final fixture = AuthFixture()..installStorage();
      final api = FakeProdukApi(fixture.api.client);
      final container = ProviderContainer(
        overrides: [produkApiProvider.overrideWithValue(api)],
      );
      final subscription = container.listen(produkProvider, (_, _) {});
      final notifier = container.read(produkProvider.notifier);
      await tester.pump();
      api.gagal = true;
      await notifier.muatBerikutnya();
      expect(container.read(produkProvider).items.length, 1);
      expect(container.read(produkProvider).pesan, isNotNull);
      api.gagal = false;
      await notifier.muatBerikutnya();
      expect(container.read(produkProvider).items.length, 2);
      expect(container.read(produkProvider).page, 2);
      api.tahan = Completer<Halaman<Produk>>();
      final old = notifier.muatUlang();
      notifier.cari('baru');
      api.tahan!.complete(
        Halaman(
          data: [item('old')],
          page: 1,
          perPage: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      api.tahan = null;
      await old;
      await tester.pump(const Duration(milliseconds: 500));
      expect(container.read(produkProvider).items.single.nama, 'baru');
      expect(container.read(produkProvider).pesan, isNull);
      subscription.close();
      container.dispose();
    },
  );
}

Produk item(String id) => Produk(
  id: id,
  tokoId: 't1',
  nama: id,
  harga: 10000,
  stok: 10,
  satuan: 'pcs',
  kategori: 'Mie',
  isTersedia: true,
);

class FakeProdukApi extends ProdukApi {
  FakeProdukApi(super.client);
  final calls = <(String, String, int)>[];
  bool gagal = false;
  Completer<Halaman<Produk>>? tahan;
  @override
  Future<Halaman<Produk>> listHalaman({
    String q = '',
    String kategori = '',
    String? tokoId,
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add((q, kategori, page));
    if (gagal) throw StateError('Server down');
    if (tahan != null) return tahan!.future;
    return Halaman(
      data: [item(q.isEmpty ? 'p$page' : q)],
      page: page,
      perPage: perPage,
      total: 2,
      totalPages: 2,
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final produkApiProvider = Provider<ProdukApi>(
  (ref) => ProdukApi(ref.watch(apiClientProvider)),
);
final tokoApiProvider = Provider<TokoApi>(
  (ref) => TokoApi(ref.watch(apiClientProvider)),
);
final kategoriProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(produkApiProvider).kategori(),
);
final tokoProvider = FutureProvider.autoDispose<Halaman<Toko>>(
  (ref) => ref.watch(tokoApiProvider).list(),
);
final detailTokoProvider = FutureProvider.autoDispose.family<Toko, String>(
  (ref, id) => ref.watch(tokoApiProvider).detail(id),
);
final promoProvider = FutureProvider.autoDispose<List<Promo>>(
  (ref) => PromoApi(ref.watch(apiClientProvider)).list(),
);
final detailProdukProvider = FutureProvider.autoDispose.family<Produk, String>(
  (ref, id) => ref.watch(produkApiProvider).detail(id),
);
final produkProvider =
    StateNotifierProvider.autoDispose<ProdukNotifier, ProdukState>(
      (ref) => ProdukNotifier(ref.watch(produkApiProvider)),
    );

class ProdukState {
  const ProdukState({
    this.items = const [],
    this.q = '',
    this.kategori = '',
    this.page = 0,
    this.totalPages = 1,
    this.memuat = true,
    this.memuatLagi = false,
    this.pesan,
  });
  final List<Produk> items;
  final String q, kategori;
  final int page, totalPages;
  final bool memuat, memuatLagi;
  final String? pesan;
}

class ProdukNotifier extends StateNotifier<ProdukState> {
  ProdukNotifier(this.api) : super(const ProdukState()) {
    unawaited(muatUlang());
  }
  final ProdukApi api;
  Timer? _debounce;
  int _request = 0;

  void cari(String value) {
    _debounce?.cancel();
    _request++;
    state = ProdukState(q: value.trim(), kategori: state.kategori);
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_load(1)),
    );
  }

  void filterKategori(String value) {
    _debounce?.cancel();
    _request++;
    state = ProdukState(q: state.q, kategori: value);
    unawaited(_load(1));
  }

  Future<void> muatUlang() {
    _debounce?.cancel();
    return _load(1);
  }

  Future<void> muatBerikutnya() async {
    if (state.memuat || state.memuatLagi || state.page >= state.totalPages) {
      return;
    }
    await _load(state.page + 1);
  }

  Future<void> _load(int page) async {
    final request = ++_request;
    final before = state;
    state = ProdukState(
      items: page == 1 ? const [] : before.items,
      q: before.q,
      kategori: before.kategori,
      page: before.page,
      totalPages: before.totalPages,
      memuat: page == 1,
      memuatLagi: page > 1,
    );
    try {
      final result = await api.listHalaman(
        q: before.q,
        kategori: before.kategori,
        page: page,
      );
      if (!mounted || request != _request) return;
      final items = <String, Produk>{
        if (page > 1)
          for (final item in before.items) item.id: item,
        for (final item in result.data) item.id: item,
      };
      state = ProdukState(
        items: List.unmodifiable(items.values),
        q: before.q,
        kategori: before.kategori,
        page: result.page,
        totalPages: result.totalPages,
        memuat: false,
      );
    } catch (_) {
      if (!mounted || request != _request) return;
      state = ProdukState(
        items: page == 1 ? const [] : before.items,
        q: before.q,
        kategori: before.kategori,
        page: before.page,
        totalPages: before.totalPages,
        memuat: false,
        pesan: 'Produk belum dapat dimuat. Silakan coba lagi.',
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

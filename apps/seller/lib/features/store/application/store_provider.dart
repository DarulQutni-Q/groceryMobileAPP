import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/network.dart';
import '../../auth/application/auth_provider.dart';

class StoreState {
  const StoreState({
    this.toko,
    this.products = const [],
    this.visible = const [],
    this.loading = false,
    this.error,
    this.busy = const {},
  });
  final Toko? toko;
  final List<Produk> products, visible;
  final bool loading;
  final String? error;
  final Set<String> busy;
}

class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier(this.tokoApi, this.produkApi)
    : super(const StoreState(loading: true)) {
    Future.microtask(load);
  }
  final TokoApi tokoApi;
  final ProdukApi produkApi;
  int _load = 0, _search = 0;
  String _q = '', _kategori = '';

  Future<void> load() async {
    final operation = ++_load;
    ++_search;
    state = StoreState(
      toko: state.toko,
      products: state.products,
      visible: state.visible,
      busy: state.busy,
      loading: true,
    );
    try {
      final results = await Future.wait<Object>([
        tokoApi.getProfil(),
        produkApi.list(),
      ]).timeout(sellerLoadLimit);
      if (!mounted || operation != _load) return;
      ++_search;
      final products = results[1] as List<Produk>;
      state = StoreState(
        toko: results[0] as Toko,
        products: products,
        visible: products,
        busy: state.busy,
      );
      if (_q.isNotEmpty || _kategori.isNotEmpty) await search(_q, _kategori);
    } catch (error) {
      if (mounted && operation == _load) {
        state = StoreState(
          toko: state.toko,
          products: state.products,
          visible: state.visible,
          busy: state.busy,
          error: authErrorMessage(error),
        );
      }
    }
  }

  Future<void> search(String q, String kategori) async {
    _q = q;
    _kategori = kategori;
    final operation = ++_search;
    try {
      final products = await produkApi
          .list(q: q, kategori: kategori)
          .timeout(sellerLoadLimit);
      if (mounted && operation == _search) {
        state = StoreState(
          toko: state.toko,
          products: state.products,
          visible: products,
          busy: state.busy,
        );
      }
    } catch (error) {
      if (mounted && operation == _search) {
        state = StoreState(
          toko: state.toko,
          products: state.products,
          visible: state.visible,
          error: authErrorMessage(error),
          busy: state.busy,
        );
      }
    }
  }

  Future<bool> mutate(String key, Future<void> Function() action) async {
    if (state.busy.contains(key)) return false;
    state = StoreState(
      toko: state.toko,
      products: state.products,
      visible: state.visible,
      busy: {...state.busy, key},
    );
    try {
      await action();
      if (!mounted) return false;
      await load();
      return mounted;
    } catch (error) {
      if (mounted) {
        state = StoreState(
          toko: state.toko,
          products: state.products,
          visible: state.visible,
          error: authErrorMessage(error),
          busy: state.busy,
        );
      }
      return false;
    } finally {
      if (mounted) {
        state = StoreState(
          toko: state.toko,
          products: state.products,
          visible: state.visible,
          error: state.error,
          busy: {...state.busy}..remove(key),
        );
      }
    }
  }
}

final tokoApiProvider = Provider(
  (ref) => TokoApi(ref.watch(apiClientProvider)),
);
final produkApiProvider = Provider(
  (ref) => ProdukApi(ref.watch(apiClientProvider)),
);
final storeProvider = StateNotifierProvider.autoDispose
    .family<StoreNotifier, StoreState, String>(
      (ref, userId) => StoreNotifier(
        ref.watch(tokoApiProvider),
        ref.watch(produkApiProvider),
      ),
    );

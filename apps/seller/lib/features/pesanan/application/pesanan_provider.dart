import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

const pesananTabs = ['baru', 'diproses', 'selesai'];
String pesananTab(String status) => switch (status) {
  'dikemas' || 'diantar' => 'diproses',
  'dibatalkan' || 'ditolak' => 'selesai',
  _ => status,
};

class PesananState {
  const PesananState({
    this.orders = const [],
    this.loading = false,
    this.error,
    this.busy = const {},
  });
  final List<Pesanan> orders;
  final bool loading;
  final String? error;
  final Set<String> busy;
  List<Pesanan> forTab(String tab) =>
      orders.where((p) => pesananTab(p.status) == tab).toList();
}

class PesananNotifier extends StateNotifier<PesananState> {
  PesananNotifier(this.api) : super(const PesananState(loading: true)) {
    Future.microtask(load);
  }
  final PesananApi api;
  int _revision = 0;
  Future<void> load() async {
    final revision = ++_revision;
    try {
      final orders = await api.list();
      if (mounted && revision == _revision) {
        state = PesananState(orders: orders, busy: state.busy);
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        state = PesananState(
          orders: state.orders,
          error: authErrorMessage(error),
          busy: state.busy,
        );
      }
    }
  }

  Future<Pesanan?> change(String id, Future<Pesanan> Function() action) async {
    if (state.busy.contains(id)) return null;
    ++_revision;
    state = PesananState(orders: state.orders, busy: {...state.busy, id});
    try {
      final updated = await action();
      if (!mounted) return null;
      ++_revision;
      state = PesananState(
        orders: state.orders.map((p) => p.id == id ? updated : p).toList(),
        busy: state.busy,
      );
      unawaited(load());
      return updated;
    } catch (error) {
      if (mounted) {
        state = PesananState(
          orders: state.orders,
          error: authErrorMessage(error),
          busy: state.busy,
        );
      }
      return null;
    } finally {
      if (mounted) {
        state = PesananState(
          orders: state.orders,
          error: state.error,
          busy: {...state.busy}..remove(id),
        );
      }
    }
  }
}

final pesananApiProvider = Provider(
  (ref) => PesananApi(ref.watch(apiClientProvider)),
);
final pesananProvider = StateNotifierProvider.autoDispose
    .family<PesananNotifier, PesananState, String>(
      (ref, userId) => PesananNotifier(ref.watch(pesananApiProvider)),
    );
typedef PesananKey = ({String userId, String id});
final pesananDetailProvider = FutureProvider.autoDispose
    .family<Pesanan, PesananKey>(
      (ref, key) => ref.watch(pesananApiProvider).detail(key.id),
    );

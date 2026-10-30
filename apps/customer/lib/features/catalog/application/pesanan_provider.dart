import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

/// API pesanan dari backend.
final pesananApiProvider = Provider<PesananApi>(
  (ref) => PesananApi(ref.watch(apiClientProvider)),
);

/// Daftar pesanan pelanggan yang sedang login, dari GET /pesanan.
final pesananProvider = FutureProvider.autoDispose<List<Pesanan>>(
  (ref) => ref.watch(pesananApiProvider).list(),
);

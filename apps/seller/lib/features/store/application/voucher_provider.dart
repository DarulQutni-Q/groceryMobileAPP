import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final voucherApiProvider = Provider<VoucherApi>(
  (ref) => VoucherApi(ref.watch(apiClientProvider)),
);

/// Semua voucher toko sendiri, untuk kelola voucher seller.
final voucherListProvider = FutureProvider.autoDispose<List<Voucher>>(
  (ref) => ref.watch(voucherApiProvider).listMine(),
);

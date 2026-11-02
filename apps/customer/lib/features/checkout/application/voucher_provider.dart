import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final voucherApiProvider = Provider<VoucherApi>(
  (ref) => VoucherApi(ref.watch(apiClientProvider)),
);

/// Voucher aktif milik satu toko, untuk pemilih voucher checkout.
final voucherListProvider =
    FutureProvider.autoDispose.family<List<Voucher>, String>(
      (ref, tokoId) => ref.watch(voucherApiProvider).listToko(tokoId),
    );

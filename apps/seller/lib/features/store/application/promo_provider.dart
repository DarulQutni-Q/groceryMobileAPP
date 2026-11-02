import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final promoHargaApiProvider = Provider<PromoHargaApi>(
  (ref) => PromoHargaApi(ref.watch(apiClientProvider)),
);

/// Semua promo toko sendiri, untuk kelola promo seller.
final promoHargaListProvider = FutureProvider.autoDispose<List<PromoHarga>>(
  (ref) => ref.watch(promoHargaApiProvider).listMine(),
);

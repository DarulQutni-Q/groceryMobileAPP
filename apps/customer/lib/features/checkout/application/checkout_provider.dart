import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final alamatApiProvider = Provider<AlamatApi>(
  (ref) => AlamatApi(ref.watch(apiClientProvider)),
);
final checkoutApiProvider = Provider<CheckoutApi>(
  (ref) => CheckoutApi(ref.watch(apiClientProvider)),
);
final alamatProvider = FutureProvider.autoDispose<List<Alamat>>(
  (ref) => ref.watch(alamatApiProvider).list(),
);
final pendingCheckoutProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authProvider).user;
  return user != null &&
      await ref.watch(storageProvider).readCheckout(user.id) != null;
});

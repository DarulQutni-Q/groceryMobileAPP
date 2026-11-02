import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(apiClientProvider)),
);

/// Riwayat chat satu pesanan (customer). Invalidate untuk muat ulang.
final chatListProvider =
    FutureProvider.autoDispose.family<List<ChatPesan>, String>(
      (ref, pesananId) => ref.watch(chatApiProvider).list(pesananId),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final chatApiTokoProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(apiClientProvider), sisiToko: true),
);

/// Riwayat chat satu pesanan (toko). Invalidate untuk muat ulang.
final chatTokoListProvider =
    FutureProvider.autoDispose.family<List<ChatPesan>, String>(
      (ref, pesananId) => ref.watch(chatApiTokoProvider).list(pesananId),
    );

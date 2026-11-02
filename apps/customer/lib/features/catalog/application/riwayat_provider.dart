import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import 'pesanan_provider.dart';

/// Jejak status satu pesanan (dari backend, bukan turunan status).
final riwayatProvider =
    FutureProvider.autoDispose.family<List<RiwayatStatus>, String>(
      (ref, pesananId) => ref.watch(pesananApiProvider).riwayat(pesananId),
    );

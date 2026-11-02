import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';

final notifikasiApiProvider = Provider<NotifikasiApi>(
  (ref) => NotifikasiApi(ref.watch(apiClientProvider)),
);

/// Daftar notifikasi tersimpan milik pengguna + jumlah belum dibaca.
/// Dipakai halaman Notifikasi dan badge bel di Home, jadi keduanya selalu
/// membaca sumber yang sama, bukan lagi sinyal checkout tertunda.
final notifikasiProvider = FutureProvider.autoDispose<NotifikasiList>(
  (ref) => ref.watch(notifikasiApiProvider).list(),
);

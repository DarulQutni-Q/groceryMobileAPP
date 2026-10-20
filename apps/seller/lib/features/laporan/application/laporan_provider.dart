import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/network.dart';
import '../../auth/application/auth_provider.dart';

class LaporanData {
  const LaporanData(this.ringkasan, this.produk);
  final RingkasanLaporan ringkasan;
  final List<ProdukTerlaris> produk;
}

typedef LaporanKey = ({String userId, String range});
final laporanApiProvider = Provider(
  (ref) => LaporanApi(ref.watch(apiClientProvider)),
);
final laporanProvider = FutureProvider.autoDispose
    .family<LaporanData, LaporanKey>((ref, key) async {
      final api = ref.watch(laporanApiProvider);
      final results = await Future.wait<Object>([
        api.getRingkasan(range: key.range),
        api.getProdukTerlaris(range: key.range, limit: 6),
      ]).timeout(sellerLoadLimit);
      return LaporanData(
        results[0] as RingkasanLaporan,
        results[1] as List<ProdukTerlaris>,
      );
    });

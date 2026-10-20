import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../shared/auth_layout.dart';
import '../../auth/application/auth_provider.dart';
import '../../store/presentation/store_widgets.dart';
import '../application/laporan_provider.dart';
import 'laporan_chart.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({
    super.key,
    required this.userId,
    required this.namaToko,
    required this.openOrders,
  });
  final String userId, namaToko;
  final VoidCallback openOrders;
  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  String _range = '7h';
  LaporanKey get _key => (userId: widget.userId, range: _range);
  void _retry() => ref.invalidate(laporanProvider(_key));

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(laporanProvider(_key));
    ref.listen(laporanProvider(_key), (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        storeMessage(context, authErrorMessage(next.error!), error: true);
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporan',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              Text(
                'Toko ${widget.namaToko}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 14),
              _ranges(),
            ],
          ),
        ),
        Expanded(
          child: report.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 35),
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 95,
                  color: Color(0xFF7EA895),
                ),
                const SizedBox(height: 16),
                Text(authErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _retry, child: const Text('Coba lagi')),
              ],
            ),
            data: (data) =>
                data.ringkasan.jumlahPesanan == 0 ? _empty() : _data(data),
          ),
        ),
      ],
    );
  }

  Widget _ranges() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 280),
    child: Row(
      children: [
        for (final range in ['7h', '30h'])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: range == '7h' ? 12 : 0),
              child: OutlinedButton(
                key: Key('laporan-range-$range'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor: _range == range
                      ? const Color(0xFF83AC9E)
                      : Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                onPressed: () => setState(() => _range = range),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_range == range) ...[
                      const Icon(Icons.check, color: Colors.white, size: 18),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        '${range == '7h' ? 7 : 30} Hari',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _empty() => LayoutBuilder(
    builder: (context, size) => ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        SizedBox(height: size.maxHeight * .22),
        const Center(
          child: SizedBox(
            width: 200,
            height: 174.23,
            child: ClipOval(
              child: ReferenceArtwork(
                asset: 'laporan-empty.png',
                rect: Rect.fromLTWH(136, 354, 194, 169),
                width: 200,
                semanticLabel: 'Ilustrasi laporan penjualan',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum ada data penjualan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Grafik akan muncul\nsetelah ada pesanan yang selesai',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF625B60)),
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 300,
            child: FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 58),
                textStyle: const TextStyle(fontSize: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.openOrders,
              child: const Text('Lihat Pesanan'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _data(LaporanData data) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Card.outlined(
        color: Colors.white,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Penjualan ${_range == '7h' ? 7 : 30} hari',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                rupiah(data.ringkasan.totalPenjualan),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _comparison(data.ringkasan),
              const SizedBox(height: 8),
              Text(
                '${data.ringkasan.jumlahPesanan} pesanan, ${data.ringkasan.jumlahProdukTerjual} produk terjual',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Penjualan per hari',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      LaporanChart(
        key: ValueKey(_range),
        days: data.ringkasan.penjualanPerHari,
      ),
      const SizedBox(height: 22),
      const Text(
        'Produk terlaris',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      for (final product in data.produk.take(5)) _product(product),
      if (data.produk.length > 5)
        TextButton(
          onPressed: () => storeMessage(context, 'Segera hadir'),
          child: const Text('Lihat semua'),
        ),
    ],
  );

  Widget _comparison(RingkasanLaporan summary) {
    final value = summary.perbandinganPersen;
    final color = value < 0 ? const Color(0xFFB3261E) : const Color(0xFF3B6341);
    final percent = value
        .abs()
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '')
        .replaceAll('.', ',');
    return Row(
      children: [
        Icon(
          value < 0 ? Icons.arrow_downward : Icons.arrow_upward,
          size: 19,
          color: color,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            summary.adaPembanding
                ? '${value < 0 ? '-' : '+'}$percent% dari ${_range == '7h' ? 'minggu lalu' : '30 hari sebelumnya'}'
                : '0% - Belum ada pembanding',
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  Widget _product(ProdukTerlaris product) {
    final photo = product.fotoUrl;
    final url = photo == null
        ? null
        : Uri.parse(ref.watch(apiBaseUrlProvider)).resolve(photo).toString();
    return Card.outlined(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 52,
          height: 52,
          child: url == null
              ? const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF7EA895),
                  size: 38,
                )
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) =>
                      const Icon(Icons.broken_image_outlined),
                ),
        ),
        title: Text(product.nama, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${product.totalQty} terjual\n'),
              TextSpan(
                text: rupiah(product.totalRupiah),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

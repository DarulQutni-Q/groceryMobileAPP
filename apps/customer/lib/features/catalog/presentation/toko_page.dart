import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart';

/// Halaman satu toko: info toko dari GET /toko/{id} lalu katalog toko itu.
/// Kartu produknya ProductCard varian katalog yang sama dengan CatalogPage
/// (tanpa badge/harga coret placeholder), jadi tap kartu dan + Keranjang
/// berperilaku persis seperti di katalog. Hanya field yang benar-benar
/// dikembalikan TokoDetail yang ditampilkan; field kosong disembunyikan,
/// tidak ada rating, pengikut, atau foto buatan.
class TokoPage extends ConsumerWidget {
  const TokoPage(this.tokoId, {super.key});
  final String tokoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toko = ref.watch(detailTokoProvider(tokoId));
    return toko.when(
      loading: () => const Scaffold(
        body: Column(
          children: [
            LimeHeader(title: 'Toko'),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
      error: (_, _) => Scaffold(
        body: Column(
          children: [
            const LimeHeader(title: 'Toko'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Info toko belum dapat dimuat.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        key: const Key('toko-retry'),
                        onPressed: () =>
                            ref.invalidate(detailTokoProvider(tokoId)),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (value) {
        final produk = value.produk ?? const <Produk>[];
        return Scaffold(
          body: Column(
            children: [
              LimeHeader(
                title: value.nama,
                height: 200,
                below: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.status == 'buka' ? 'Buka' : value.status,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: gardenInk,
                      ),
                    ),
                    if (_jam(value) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _jam(value)!,
                        style: const TextStyle(fontSize: 12, color: gardenInk),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _InfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Alamat',
                                  value: value.alamat,
                                ),
                                if (value.telepon.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Telepon',
                                    value: value.telepon,
                                  ),
                                if (value.deskripsi != null &&
                                    value.deskripsi!.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.info_outlined,
                                    label: 'Tentang',
                                    value: value.deskripsi!,
                                  ),
                                if (value.kategori.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.category_outlined,
                                    label: 'Kategori',
                                    value: value.kategori.join(', '),
                                  ),
                                if (value.metodeKirim.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.delivery_dining_outlined,
                                    label: 'Pengiriman',
                                    value: value.metodeKirim.join(', '),
                                  ),
                                _InfoRow(
                                  icon: Icons.my_location_outlined,
                                  label: 'Radius',
                                  value: '${value.radiusKm} km',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            const Text(
                              'Katalog Toko',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: gardenInk,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${produk.length} produk',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (produk.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Belum ada produk di toko ini',
                              key: Key('toko-empty'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textGrey),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisExtent:
                                260 +
                                (MediaQuery.textScalerOf(
                                      context,
                                    ).scale(100) -
                                    100),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: produk.length,
                          itemBuilder: (_, index) =>
                              ProductCard(produk[index]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Jam dari field jam_buka/jam_tutup TokoDetail, dipotong ke HH:MM seperti
/// yang dipakai kartu toko di keranjang ("Buka s/d ..."). Null kalau
/// kedua field tidak ada.
String? _jam(Toko toko) {
  String potong(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
  final buka = toko.jamBuka;
  final tutup = toko.jamTutup;
  if (buka != null && tutup != null) {
    return 'Buka ${potong(buka)} - ${potong(tutup)}';
  }
  if (tutup != null) return 'Buka s/d ${potong(tutup)}';
  if (buka != null) return 'Buka mulai ${potong(buka)}';
  return null;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: gardenInk),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: textGrey),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

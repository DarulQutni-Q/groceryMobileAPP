import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../../checkout/application/checkout_provider.dart';
import '../application/jarak_toko.dart';

/// Dialog tengah "Pilih Toko": daftar toko buka + kolom cari + gating radius.
///
/// Disajikan sebagai Dialog di tengah layar (bukan bottom sheet):
/// lebar = layar - 48, tinggi maks 80% layar, daftar di dalamnya
/// bisa di-scroll. Semua perilaku (cari, gating radius, navigasi)
/// sama persis seperti sebelumnya; yang berubah hanya wadahnya.
///
/// - Cari: ketik nama/alamat (case-insensitive contains). Kosongkan =
///   kembali ke daftar penuh. Tidak ada yang cocok = teks jujur, bukan
///   toko karangan.
/// - Radius: jarak = haversine dari alamat UTAMA user ke toko. Jarak
///   diketahui dan melebihi radius_km toko -> tile diabukan dan tidak
///   bisa dipilih; ketuk tile itu menampilkan dialog penjelasan (jarak
///   user vs maks toko), bukan tile mati tanpa penjelasan. Jarak tidak
///   diketahui (toko tanpa koordinat, alamat utama tanpa GPS, atau
///   alamat gagal dimuat) -> toko TETAP bisa dipilih; jangan blokir
///   order sah gara-gara data belum ada. Radius tetap ditampilkan.
/// - Koordinat toko hari ini belum dikembalikan backend (model Toko
///   tidak punya kolom latitude/longitude), jadi di produksi jarak
///   selalu tidak diketahui sampai backend menambahkannya. Field
///   latitude/longitude di model Dart sudah disiapkan (nullable) supaya
///   gating langsung aktif begitu backend mengirimkannya, tanpa ubah UI.
class PilihTokoDialog extends ConsumerStatefulWidget {
  const PilihTokoDialog({super.key, required this.stores, required this.onPilih});

  /// Daftar toko buka dari GET /toko (sudah difilter status buka).
  final List<Toko> stores;

  /// Dipanggil saat toko yang BOLEH dipilih diketuk. Pemanggil yang
  /// menutup dialog dan membuka TokoPage (butuh context luar dialog).
  final ValueChanged<Toko> onPilih;

  @override
  ConsumerState<PilihTokoDialog> createState() => _PilihTokoDialogState();
}

class _PilihTokoDialogState extends ConsumerState<PilihTokoDialog> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Koordinat alamat utama user; null kalau tidak ada alamat utama
  /// atau alamat utama belum punya GPS. Hanya alamat utama yang dipakai:
  /// itulah tujuan antar default (pola yang sama dipakai checkout).
  ({double lat, double lon})? _userCoords(List<Alamat> addresses) {
    for (final address in addresses) {
      if (address.isUtama) {
        if (address.latitude == null || address.longitude == null) {
          return null;
        }
        return (lat: address.latitude!, lon: address.longitude!);
      }
    }
    return null;
  }

  void _jelaskanDiLuarJangkauan(Toko store, double jarakKm) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Di luar jangkauan'),
        content: Text(
          'Jarak kamu ke ${store.nama} ${formatJarakKm(jarakKm)}, '
          'sedangkan maks pengantaran toko ini ${store.radiusKm} km.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _tile(Toko store, ({double lat, double lon})? user) {
    final jarakKm = jarakKeToko(
      userLat: user?.lat,
      userLon: user?.lon,
      tokoLat: store.latitude,
      tokoLon: store.longitude,
    );
    final boleh = tokoDapatDipilih(
      jarakKm: jarakKm,
      radiusKm: store.radiusKm,
    );
    final jarakText = jarakKm == null
        ? 'Maks ${store.radiusKm} km'
        : 'Jarak ${formatJarakKm(jarakKm)} • Maks ${store.radiusKm} km';
    return ListTile(
      key: Key('store-pick-${store.id}'),
      leading: const CircleAvatar(
        radius: 17,
        backgroundColor: Color(0xFFE9F4DD),
        child: Icon(
          Icons.house_outlined,
          size: 20,
          color: gardenInk,
        ),
      ),
      title: Text(
        store.nama,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: boleh ? null : textGrey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.alamat,
            style: TextStyle(color: boleh ? null : textGrey),
          ),
          Text(
            boleh ? jarakText : '$jarakText • Di luar jangkauan',
            style: const TextStyle(fontSize: 12, color: textGrey),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: textGrey,
      ),
      onTap: () {
        if (!boleh) {
          // jarakKm tidak null di sini: boleh=false hanya terjadi saat
          // jarak diketahui dan melebihi radius (lihat tokoDapatDipilih).
          _jelaskanDiLuarJangkauan(store, jarakKm!);
          return;
        }
        widget.onPilih(store);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alamatAsync = ref.watch(alamatProvider);
    final user = alamatAsync.maybeWhen(
      data: (list) => _userCoords(list),
      orElse: () => null,
    );
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.stores
        : widget.stores
            .where(
              (store) =>
                  store.nama.toLowerCase().contains(query) ||
                  store.alamat.toLowerCase().contains(query),
            )
            .toList();
    return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Pilih Toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            if (widget.stores.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('store-search'),
                  controller: _search,
                  style: const TextStyle(fontSize: 13),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari toko...',
                    hintStyle: const TextStyle(fontSize: 13),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('clear-store-search'),
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _search.clear();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            if (widget.stores.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text('Belum ada toko buka'),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text('Tidak ada toko yang cocok'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final store in filtered) _tile(store, user),
                  ],
                ),
              ),
          ],
        );
  }
}
